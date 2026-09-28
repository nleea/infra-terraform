# infra-terraform

Infraestructura como código en AWS con Terraform: red (VPC), cómputo (ECS), base de datos (RDS), balanceador (ALB), roles IAM y seguridad.

## Documentación

| Documento | Contenido |
|---|---|
| [Pipeline y despliegue](docs/01-pipeline-y-despliegue.md) | Validación, aprobación, despliegue dev → prod, drift y rollback |
| [Ramas, secretos y credenciales](docs/02-ramas-secretos-credenciales.md) | Trunk-based, OIDC, roles, Secrets Manager, protección del estado |
| [ADR de cómputo](docs/03-adr-computo-ec2-ecs-eks.md) | EC2 vs ECS vs EKS y cómo soportar las tres |
| [Escalabilidad](docs/04-escalabilidad.md) | Aplicación, plataforma (multicuenta) y organización |
| [Seguridad y Zero Trust](docs/05-seguridad-y-zero-trust.md) | Controles implementados y propuestos, por principio |
| [Guion del video](docs/guion-video.md) | Recorrido de 15 minutos por los 7 puntos |
| `docs/arquitectura-general.drawio` | Visión general (pipeline + AWS) y opciones de cómputo |
| `docs/arquitectura-dev.drawio` | Detalle de red y servicios de dev, y CI/CD con permisos |

## Estructura

```
infra-terraform/
├── .github/
│   ├── CODEOWNERS
│   ├── dependabot.yml
│   ├── actions/terraform-init/
│   └── workflows/
│       ├── terraform-plan.yml      (PR: gitleaks, fmt, validate, tflint, checkov, plan)
│       ├── terraform-apply.yml     (main: dev → aprobación → prod)
│       ├── _terraform-deploy.yml   (reutilizable: plan + apply de un entorno)
│       └── terraform-drift.yml     (diario: detecta cambios manuales)
├── docs/
│   ├── 01-pipeline-y-despliegue.md
│   ├── 02-ramas-secretos-credenciales.md
│   ├── 03-adr-computo-ec2-ecs-eks.md
│   ├── 04-escalabilidad.md
│   ├── 05-seguridad-y-zero-trust.md
│   ├── guion-video.md
│   ├── arquitectura-general.drawio
│   └── arquitectura-dev.drawio
├── bootstrap/
│   ├── dev/    (backend de estado + roles IAM de Terraform, estado local)
│   └── prod/
├── environments/
│   ├── dev/    (main, variables, outputs, terraform.tfvars, backend, providers, versions, locals)
│   └── prod/   (main, variables, outputs, terraform.tfvars, backend, providers, versions, locals)
├── modules/
│   ├── vpc/
│   ├── ecs-cluster/
│   ├── ecs-service/
│   ├── rds/
│   ├── iam-roles/
│   ├── kms-key/
│   ├── platform/     (composición completa de un entorno)
│   ├── alb/
│   ├── security/
│   ├── waf/
│   └── terraform-bootstrap/
├── policies/
│   └── checkov-skip.yml
├── .gitignore
├── .terraform-version
└── README.md
```

## environments/ y modules/

- `modules/` contiene componentes reutilizables (cada uno con `main.tf`, `variables.tf` y `outputs.tf`).
- `environments/dev` y `environments/prod` son los puntos de entrada: cada uno invoca los módulos con sus propios valores (`terraform.tfvars`) y tiene su propio estado remoto configurado en `backend.tf`, de modo que dev y prod quedan aislados.

## Providers y credenciales

Cada entorno tiene su propio `providers.tf`, idéntico en estructura y parametrizado por `terraform.tfvars`:

- `allowed_account_ids`: el provider falla si las credenciales apuntan a otra cuenta (evita aplicar dev en prod).
- `default_tags`: `Project`, `Environment`, `Owner`, `CostCenter`, `ManagedBy`, `Repository` en todos los recursos (definidos en `locals.tf`).
- `assume_role` opcional (`assume_role_arn`) y `aws_profile` opcional para uso local; en CI ambos quedan en `null` y las credenciales llegan por OIDC.
- Versiones fijadas en `versions.tf` (Terraform `~> 1.9`, AWS `~> 6.0`) y `.terraform.lock.hcl` versionado con hashes para linux y macOS.

## Bootstrap (una vez por cuenta)

`bootstrap/<env>` usa el módulo `terraform-bootstrap` para crear, con credenciales de administrador:

- Bucket S3 de estado (versionado, KMS, TLS obligatorio, sin acceso público) y tabla DynamoDB de lock.
- OIDC provider de GitHub (`create_github_oidc_provider = false` si ya existe en la cuenta).
- Rol `terraform-plan`: `ReadOnlyAccess` + lectura del estado + lock. Lo asumen los pull requests del repo.
- Rol `terraform-apply`: gestión de los servicios del stack (EC2/VPC, ECS, ELB, RDS, Logs, CloudWatch, KMS, Secrets Manager, SSM, ACM, Autoscaling) solo en la región del entorno; IAM limitado a recursos `<project>-<env>-*`; `PassRole` solo hacia ECS/RDS; denegación explícita sobre los roles de Terraform y el backend de estado. Lo asume el GitHub Environment `<env>`.

```bash
cd bootstrap/dev
AWS_PROFILE=<admin-dev> terraform init && terraform apply
terraform output -raw backend_config > ../../environments/dev/backend.hcl
```

Guardar `plan_role_arn` / `apply_role_arn` como variables del repositorio/GitHub Environment para los workflows. Después, migrar el estado local del bootstrap al bucket creado (`terraform init -migrate-state` tras añadir un backend `s3` con key `bootstrap/terraform.tfstate`).

## Uso de un entorno

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
TF_VAR_aws_profile=<perfil-dev> terraform plan
```

## CI

| Archivo | Qué hace |
|---|---|
| `.github/actions/terraform-init` | Acción compuesta: versión de `.terraform-version`, región de `terraform.tfvars`, credenciales AWS por OIDC y `init` con `backend.hcl`. |
| `terraform-plan.yml` | En PRs: `fmt`, `validate`, `tflint`, `checkov` y `plan` por entorno (detectados desde `environments/`), con el plan comentado en el PR. Usa el rol `plan`. |
| `terraform-apply.yml` | En push a `main` o manual: despliega `dev` y después `prod`, en serie y sin cancelar ejecuciones en curso. |
| `_terraform-deploy.yml` | Workflow reutilizable: `plan` con el rol de lectura, guarda el plan como artifact (1 día), y `apply` de ese mismo plan en el GitHub Environment con el rol `apply`. Si no hay cambios no pide aprobación. |

### Configuración en GitHub

- Variable de repositorio `AWS_PLAN_ROLE_ARNS` (JSON con el output `plan_role_arn` de cada bootstrap):
  `{"dev":"arn:aws:iam::111111111111:role/terraform/simonmovi-dev-terraform-plan","prod":"arn:aws:iam::222222222222:role/terraform/simonmovi-prod-terraform-plan"}`
- GitHub Environments `dev` y `prod`, cada uno con la variable `AWS_APPLY_ROLE_ARN` (output `apply_role_arn`). En `prod` configurar *Required reviewers* y limitar *Deployment branches* a `main`.
- Commitear `environments/<env>/backend.hcl` (output `backend_config`; no contiene secretos).

El trust de cada rol está atado al contexto del job: `plan` acepta PRs y la rama `main`; `apply` solo el GitHub Environment de su entorno.

## Arquitectura de dev

Diagrama editable en [`docs/arquitectura-dev.drawio`](docs/arquitectura-dev.drawio), con dos páginas:
**Arquitectura dev** (red, servicios y flujos de tráfico) y **CI/CD y permisos** (OIDC, roles plan/apply
y backend de estado). Se abre con draw.io Desktop, https://app.diagrams.net o la extensión
"Draw.io Integration" de VS Code.

```
Internet ─► ALB (subnets públicas) ─► servicios ECS Fargate (subnets privadas) ─► RDS PostgreSQL (subnets aisladas)
                                            │
                                            └─► NAT ─► internet (solo HTTPS)
```

- Los servicios se declaran en `services` (`terraform.tfvars`); cada uno obtiene target group, regla en el ALB, rol IAM, log group y autoescalado por CPU.
- `connect_database = true` inyecta `DB_HOST`, `DB_PORT`, `DB_NAME` y, como secrets, `DB_USERNAME`/`DB_PASSWORD` desde el secret que gestiona RDS. La contraseña nunca pasa por Terraform.
- Security groups encadenados: ALB → servicios (solo puertos de contenedor) → base de datos (solo 5432). La base de datos no tiene salida.

## dev y prod

`modules/platform` compone todo el entorno (red, ALB + WAF, ECS, RDS, IAM, KMS). `environments/dev` y
`environments/prod` tienen el mismo `main.tf` y `variables.tf`: **solo cambian los valores de `terraform.tfvars`**,
así lo que se valida en dev es exactamente lo que se despliega en prod.

| | dev (us-east-2) | prod (us-east-1) |
|---|---|---|
| VPC | 10.10.0.0/16, 2 AZs | 10.20.0.0/16, 3 AZs |
| NAT | 1 compartido | 1 por AZ |
| VPC endpoints | solo S3 (gateway) | S3 + ECR, CloudWatch Logs, Secrets Manager |
| ECS | 1 tarea on-demand + Spot, ECS Exec activo | 2 on-demand garantizadas, 3:1 on-demand/Spot, hasta 10 tareas, **sin ECS Exec** |
| RDS | db.t4g.micro, single-AZ, 7 días de backup | db.t4g.medium, **Multi-AZ**, 30 días, protección contra borrado |
| ALB | sin protección contra borrado | protección contra borrado |
| WAF | 1000 req/5 min por IP | 2000 req/5 min por IP |
| Logs | 30 días | 365 días |

El WAF aplica las reglas gestionadas de AWS (reputación de IPs, OWASP Top 10, entradas maliciosas como Log4j, SQLi)
y un límite de peticiones por IP; sus logs ocultan las cabeceras `authorization` y `cookie`.

### Pendientes

- **HTTPS**: requiere dominio y certificado ACM (`alb_certificate_arn`).
- **ECR**: la imagen de `api` es un nginx de ejemplo; falta el repositorio y el pipeline de la aplicación.

## Políticas

`policies/checkov-skip.yml` lista las reglas de checkov que se omiten, cada una con su justificación.

## Versión de Terraform

La versión está fijada en `.terraform-version` (1.9.8), compatible con `tfenv`.

cambio para probar