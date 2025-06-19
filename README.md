# 🚀 AWS Infrastructure Terraform - Microservices

Este projeto implementa uma arquitetura moderna de **microservices na AWS**, utilizando **EC2** para hospedar os serviços, **RDS MySQL** como banco de dados compartilhado e **Application Load Balancer** com roteamento baseado em caminhos. O pipeline de deploy é totalmente automatizado com **GitHub Actions**.

## 🏗️ Arquitetura

### Componentes Principais:
- **EC2 Instances** - Hospedam os microservices com Python HTTP server
- **Application Load Balancer** - Distribui tráfego com roteamento por path
- **RDS MySQL** - Banco de dados compartilhado
- **VPC** - Rede isolada com subnets públicas e privadas
- **Security Groups** - Controle de acesso granular

### Microservices Implementados:
1. **User Service** - Gerenciamento de usuários (`/users`)
2. **Order Service** - Gerenciamento de pedidos (`/orders`)

## 📁 Estrutura do Projeto

```
aws-infrastructure-terraform/
├── README.md
├── providers.tf                 # Configuração do provider AWS
├── variables.tf                 # Variáveis do projeto
├── terraform.tfvars.example     # Exemplo de variáveis
├── outputs.tf                   # Outputs dos recursos
├── data.tf                      # Data sources
├── vpc.tf                       # VPC, subnets, gateways
├── security_groups.tf           # Security groups
├── load-balancer.tf             # ALB e target groups
├── microsservices-architeture.tf # Definição dos serviços EC2
├── rds.tf                       # Banco de dados MySQL
├── iam-roles.tf                 # Roles IAM (removidas - não necessárias)
├── import_resources.sh          # Script para importar recursos existentes
└── .github/workflows/           # GitHub Actions para CI/CD
    ├── deploy.yml               # Deploy automático
    └── destroy.yml              # Destroy com aprovação manual
```

## 🛠️ Pré-requisitos

- Conta AWS com permissões adequadas (EC2, RDS, IAM, etc.)
- Terraform >= 1.0
- AWS CLI configurado
- GitHub repository com secrets configurados

## ⚙️ Configuração

### 1. Clone o repositório
```bash
git clone <seu-repositorio>
cd aws-infrastructure-terraform
```

### 2. Configure as variáveis
```bash
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars com seus valores
```

### 3. Inicialize o Terraform
```bash
terraform init
```

### 4. Planeje e aplique
```bash
terraform plan
terraform apply
```

## 🌐 Endpoints Disponíveis

Após o deploy, você terá acesso aos seguintes endpoints:

- **Load Balancer URL**: `http://<alb-dns-name>`
- **User Service**: `http://<alb-dns-name>/users`
- **Order Service**: `http://<alb-dns-name>/orders`
- **Health Check**: `http://<alb-dns-name>` (retorna mensagem padrão)

### Exemplo de Resposta:
```json
{
  "message": "User Service is running!",
  "service": "users", 
  "status": "active",
  "path": "/users"
}
```

## 🔧 Funcionalidades

### Roteamento Inteligente
- `/users/*` → User Service
- `/orders/*` → Order Service
- Outros paths → Mensagem padrão

### Alta Disponibilidade
- Instâncias EC2 em múltiplas AZs
- Health checks automáticos
- Auto-scaling configurável

### Segurança
- VPC isolada
- Security groups restritivos
- Subnets públicas e privadas
- RDS em subnet privada

## 🚀 CI/CD Pipeline

### Deploy Automático
- Trigger: Push para `main`
- Executa: `terraform plan` e `terraform apply`
- Notificação: Status no GitHub

### Destroy Manual
- Trigger: Workflow dispatch manual
- Proteção: Requer aprovação
- Cleanup: Remove todos os recursos

## 📊 Monitoramento

### Health Checks
- Path: `/` 
- Intervalo: 30s
- Timeout: 10s
- Healthy threshold: 2
- Unhealthy threshold: 3

### Logs
- Application logs: `/tmp/server.log` nas instâncias EC2
- Load balancer logs: CloudWatch (se habilitado)

## 🔒 Segurança

### Network Security
- VPC com CIDR `10.0.0.0/16`
- Subnets públicas: `10.0.1.0/24`, `10.0.2.0/24`
- Subnets privadas: `10.0.3.0/24`, `10.0.4.0/24`

### Security Groups
- **ALB**: Permite HTTP (80) de qualquer lugar
- **EC2**: Permite HTTP (80) apenas do ALB
- **RDS**: Permite MySQL (3306) apenas do EC2

## 📈 Escalabilidade

### Horizontal Scaling
- Adicione mais instâncias EC2
- Configure Auto Scaling Groups
- Ajuste target groups

### Vertical Scaling  
- Altere `instance_type` nas variáveis
- Aplique com `terraform apply`

## 🛠️ Troubleshooting

### Problemas Comuns

1. **503 Service Unavailable**
   - Verifique se as instâncias EC2 estão healthy
   - Confirme se o Python server está rodando
   - Verifique os security groups

2. **Connection Timeout**
   - Verifique se as instâncias estão em subnets públicas
   - Confirme se o Internet Gateway está configurado
   - Verifique as route tables

3. **Database Connection Issues**
   - Verifique se o RDS está na subnet privada
   - Confirme os security groups do RDS
   - Teste conectividade das instâncias EC2

### Comandos Úteis

```bash
# Verificar status das instâncias
terraform show | grep -A 5 "aws_instance"

# Testar endpoints diretamente
curl -v http://<instance-ip>

# Verificar logs do servidor
# (conectar via SSH na instância)
tail -f /tmp/server.log
```

## 📝 Variáveis de Configuração

| Variável | Descrição | Padrão |
|----------|-----------|---------|
| `project_name` | Nome do projeto | `rogerio-aws-infrastructure` |
| `environment` | Ambiente (dev/prod) | `dev` |
| `region` | Região AWS | `us-east-2` |
| `instance_type` | Tipo da instância EC2 | `t3.micro` |
| `db_instance_class` | Classe da instância RDS | `db.t3.micro` |

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Desenvolvido com ❤️ por Rogério Bayer**

