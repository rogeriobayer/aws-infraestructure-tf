# AWS Infrastructure with Terraform

Este projeto provisiona automaticamente uma arquitetura padrão na AWS utilizando Terraform. Os principais recursos criados são:

- Instâncias **EC2 Linux** com **Auto Scaling Group**.
- **Application Load Balancer** (HTTP).
- Banco de dados **RDS MySQL** em subnets privadas.
- **VPC** com subnets públicas/privadas, **Internet Gateway** e roteamento.
- **Security Groups** segmentados para cada camada.

---

## ✅ Pré-requisitos

- Terraform >= **1.0**
- AWS CLI configurada
- Conta AWS com permissões para criar **EC2**, **VPC**, **RDS** e **ELB**

---

## 🚀 Como usar

1. Clone o repositório e acesse o diretório:

   ```bash
   git clone <url-repositorio>
   cd aws-infrastructure-terraform
   ```

2. Configure as variáveis copiando o exemplo:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edite `terraform.tfvars` com sua **região**, **senha do banco**, etc.

4. Inicialize o Terraform:

   ```bash
   terraform init
   ```

5. Valide e planeje a infraestrutura:

   ```bash
   terraform validate
   terraform plan
   ```

6. Aplique a configuração:

   ```bash
   terraform apply
   ```

7. Após a execução, acesse a aplicação pela URL informada no output `application_url`.

---

## 📁 Estrutura dos Arquivos

- `providers.tf`: Configuração do provider AWS.
- `variables.tf`: Variáveis customizáveis.
- `data.tf`: Busca de AMI e zonas de disponibilidade.
- `vpc.tf`: Infraestrutura de rede.
- `security_groups.tf`: Grupos de segurança.
- `ec2.tf`: Templates e auto scaling das EC2.
- `load_balancer.tf`: Load Balancer.
- `rds.tf`: Banco de dados MySQL.
- `outputs.tf`: Referências/facilidade de acesso.
- `terraform.tfvars`: Valores das variáveis.

---

## 🧹 Limpeza

Para destruir todos os recursos e evitar cobranças, execute:

```bash
terraform destroy
```

---

## ℹ️ Observações

- Todos os parâmetros podem ser personalizados em `terraform.tfvars`.
- O projeto segue boas práticas de segmentação de rede e segurança.
- A **senha do banco** não é exibida nos outputs públicos.
