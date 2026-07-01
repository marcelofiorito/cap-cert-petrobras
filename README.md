# Gestão de Certificações O&G — SAP SuccessFactors Extension

> **Extensão SAP CAP** para controle de habilitações técnicas obrigatórias em empresas do setor de Óleo & Gás, integrada ao SAP SuccessFactors via OData API.  
> Versão `1.0.0` · Deploy: SAP BTP Cloud Foundry · Interface: SAP Fiori Elements

---

## 🔗 Acesso Rápido — Ambiente de Demonstração

| | URL |
|---|---|
| **Interface Fiori (App)** | `https://sa-build-platform-org-dev-cap-cert-petrobras-approuter.cfapps.us10.hana.ondemand.com/certmanagement/index.html` |
| **OData API (CAP)** | `https://sa-build-platform-org-dev-cap-cert-petrobras-srv.cfapps.us10.hana.ondemand.com/CertService` |
| **Metadata OData** | `.../CertService/$metadata` |
| **MCP Server (Joule)** | `https://joule-sfsf-mcp.cfapps.us10.hana.ondemand.com/mcp` |
| **SFSF API Server** | `https://apisalesdemo8.successfactors.com` (instância SFSALES010674) |

> Autenticação via SAP BTP XSUAA — subaccount `build-platform-rfm61ms1` (US10).

---

## Descrição de Negócio

### O Problema

Empresas de Óleo & Gás como a Petrobras têm **obrigação regulatória e operacional** de manter seus colaboradores com as certificações técnicas em dia. Uma NR-33 (Espaço Confinado) vencida não é apenas uma infração trabalhista — é um risco real de acidente grave ou fatal.

O SAP SuccessFactors, na sua configuração padrão, **não possui uma entidade nativa para controle de certificações técnicas** (NRs, OPITO, NEBOSH etc.). Cada empresa gerencia isso em planilhas Excel, sistemas legados desconectados ou processos manuais, gerando:

- **Risco de compliance**: funcionários atuando com certificações vencidas
- **Retrabalho operacional**: renovações emergenciais por falta de controle preventivo
- **Invisibilidade para a liderança**: impossibilidade de saber o status de certificações da equipe em tempo real
- **Desconexão com o RH**: dados de certificação isolados do perfil do colaborador no SFSF

### A Solução

Esta extensão CAP cria uma **camada de dados integrada ao SuccessFactors** que:

1. Armazena certificações técnicas diretamente no SAP HANA Cloud, vinculadas ao `userId` do SFSF
2. Calcula automaticamente o status de cada habilitação em tempo real
3. Exibe alertas visuais por criticidade — vermelho (vencida), laranja (a vencer), verde (em dia)
4. Integra ao ecossistema SAP via OData V4, consumível por Joule, Fiori e APIs REST
5. Alimenta o agente Joule com 3 ferramentas conversacionais de RH específicas para certificações

---

## Arquitetura

```
┌──────────────────────────────────────────────────────────────────┐
│                      SAP BTP (Cloud Foundry US10)                │
│                                                                   │
│  ┌───────────────┐    ┌─────────────────┐    ┌───────────────┐   │
│  │  App Router   │───▶│  CAP Node.js    │───▶│  HANA Cloud   │   │
│  │ (Fiori+Auth)  │    │  OData V4 API   │    │ (HDI: cap-    │   │
│  └───────────────┘    │  /CertService   │    │  joule-db)    │   │
│                        └────────┬────────┘    └───────────────┘   │
│  ┌───────────────┐              │                                  │
│  │  HTML5 Repo   │    ┌─────────▼────────┐                        │
│  │ (Fiori bundle)│    │   MCP Server CF  │◀──── Joule Studio      │
│  └───────────────┘    │  (joule-sfsf-mcp)│                        │
│                        └─────────┬────────┘                        │
└──────────────────────────────────┼───────────────────────────────┘
                                   │ OAuth 2.0 SAML Bearer
                                   ▼
                     SAP SuccessFactors OData V2
                     apisalesdemo8.successfactors.com
                     (Employee Central, Performance, Compensation,
                      Recruitment, Goals, Learning)
```

---

## APIs Utilizadas — SAP SuccessFactors (Standard OData V2)

O MCP server consome diretamente a API padrão do SuccessFactors sem nenhuma customização no tenant. Abaixo o catálogo completo das entidades acessadas.

### Employee Central

| Entidade SFSF | Campos principais consultados | Tool MCP |
|---|---|---|
| `User` | `userId`, `firstName`, `lastName`, `jobTitle`, `department`, `email`, `performance`, `potential` | `listar_funcionarios`, `dados_funcionario` |
| `EmpJob` | `userId`, `jobTitle`, `department`, `division`, `businessUnit`, `costCenter`, `company`, `fte`, `managerId`, `payGrade`, `employeeClass`, `startDate` | `dados_funcionario`, `subordinados_diretos`, `organograma_departamento` |
| `FODepartment` | `externalCode`, `name_defaultValue`, `parent` | `organograma_departamento` |
| `Position` | `code`, `positionTitle`, `jobCode`, `status` | `organograma_departamento` |

### Recrutamento (Recruiting Management)

| Entidade SFSF | Campos principais consultados | Tool MCP |
|---|---|---|
| `JobRequisition` | `jobReqId`, `departmentCode`, `jobCode`, `status`, `openings`, `location`, `closingDate`, `hiringManager` | `vagas_internas`, `redigir_perfil_vaga` |
| `JobRequisitionLocale` | `jobReqId`, `jobTitle`, `externalTitle`, `externalJobDescription`, `locale` | `vagas_internas`, `redigir_perfil_vaga` |

### Performance & Goals

| Entidade SFSF | Campos principais consultados | Tool MCP |
|---|---|---|
| `FormHeader` | `formDataId`, `formTitle`, `rating`, `isRated`, `formTemplateType`, `formReviewStartDate`, `formReviewEndDate`, `sender` | `avaliacao_desempenho`, `sugerir_metas_gd` |
| `Goal_1` / `Goal_2` / `Goal_3` | `id`, `userId`, `name`, `metric`, `weight`, `status`, `dueDate`, `category` | `metas_funcionario` |

### Compensation

| Entidade SFSF | Campos principais consultados | Tool MCP |
|---|---|---|
| `EmpPayCompRecurring` | `userId`, `payComponent`, `amount`, `currency`, `notes` | `remuneracao_funcionario`, `consultar_remuneracao` |
| `EmpCompensation` | `userId`, `payGrade`, `payScaleType` | `remuneracao_funcionario` |
| `PayrollRunResult` | `payRunId`, `payRunDate`, `payPeriodStartDate`, `payPeriodEndDate`, `payCalendarCode` | `consultar_remuneracao` |
| `PayrollRunResultItem` | `payRunId`, `userId`, `wagetype`, `amount`, `currency` | `consultar_remuneracao` |

### Learning

| Entidade SFSF | Campos principais consultados | Tool MCP |
|---|---|---|
| `UserBadge` | `userId`, `badgeId`, `badgeName`, `issueDate` | `buscar_cursos` |

> **Nota sobre Learning OData API:** O SAP SuccessFactors Learning (LMS) expõe entidades separadas como `LearningHistory`, `LearningPlan`, `UserCourse` via o endpoint `/learning/odatav4/public/`. A instância demo SFSALES010674 tem acesso básico via `UserBadge` na API principal. Para integração completa com histórico de cursos concluídos, seria necessário ativar o módulo Learning e usar o endpoint dedicado.

---

## Extensão CAP — Entidades Próprias (HANA Cloud)

Estas entidades **não existem no SuccessFactors standard** — são criadas pela extensão CAP e armazenadas no HANA Cloud.

### Modelo de Dados

```
TipoCertificacao          HabilitacaoFuncionario        AlertaCertificacao
─────────────────         ──────────────────────────    ─────────────────────
codigo (PK)               ID (UUID, PK)                 ID (UUID, PK)
nome                      userId  ──────────────────▶   habilitacao (FK)
descricao                 nomeCompleto       SFSF User   tipo (VENCIDA|VENCER_30|VENCER_90)
categoria                 departamento                   dataAlerta
obrigatoriaPara           certificacao (FK)──▶TipoCert   lido
validadeMeses             dataEmissao                    userId
orgaoEmissor              dataVencimento                 certCodigo
renovavel                 statusCalculado (persistido)
                          numeroDoc
                          orgaoEmissor
                          observacao
                          arquivoUrl
```

### View Calculada

```sql
-- FuncionarioCertificacoes (view somente leitura, consumida pelo Joule)
SELECT
  HabilitacaoFuncionario.*,
  TipoCertificacao.codigo     AS certCodigo,
  TipoCertificacao.nome       AS certNome,
  TipoCertificacao.categoria  AS certCategoria,
  0 AS diasParaVencer,        -- preenchido pelo handler Node.js em tempo de execução
  0 AS criticality            -- 1=vermelho, 2=laranja, 3=verde (Fiori semantic coloring)
FROM HabilitacaoFuncionario
JOIN TipoCertificacao ON certificacao_codigo = TipoCertificacao.codigo
```

### Cálculo de Status (handler Node.js)

| Condição | `statusCalculado` | `criticality` (Fiori) |
|---|---|---|
| `dataVencimento < hoje` | `VENCIDA` | `1` (vermelho) |
| `dataVencimento ≤ hoje + 30 dias` | `VENCER_30` | `2` (laranja) |
| `dataVencimento ≤ hoje + 90 dias` | `VENCER_90` | `2` (laranja) |
| `dataVencimento > hoje + 90 dias` | `VIGENTE` | `3` (verde) |

---

## API OData V4 — CertService

**Base URL:** `https://sa-build-platform-org-dev-cap-cert-petrobras-srv.cfapps.us10.hana.ondemand.com/CertService`

### Endpoints

| Endpoint | Métodos | Descrição |
|---|---|---|
| `/TipoCertificacoes` | GET, POST, PATCH, DELETE | Catálogo de tipos de certificação |
| `/HabilitacoesFuncionario` | GET, POST, PATCH, DELETE | Registros individuais de habilitação |
| `/FuncionariosCertificacoes` | GET (readonly) | View completa com status e criticidade |
| `/AlertasCertificacao` | GET (readonly) | Alertas gerados automaticamente |
| `/StatusList` | GET (readonly) | Lista de valores para filtro de status |
| `/dashboardArea(departamento='')` | GET (function) | Compliance por área |
| `/gerarAlertas(diasAntecedencia=30)` | POST (action) | Gera novos alertas de vencimento |

### Exemplos de Queries OData

```bash
# Autenticação (XSUAA client credentials)
TOKEN=$(curl -s -X POST \
  "https://build-platform-rfm61ms1.authentication.us10.hana.ondemand.com/oauth/token" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d "grant_type=client_credentials" | jq -r '.access_token')

BASE="https://sa-build-platform-org-dev-cap-cert-petrobras-srv.cfapps.us10.hana.ondemand.com/CertService"
AUTH="Authorization: Bearer $TOKEN"

# Todas as certificações vencidas
curl "$BASE/FuncionariosCertificacoes?\$filter=statusCalculado eq 'VENCIDA'" -H "$AUTH"

# Certificações de um funcionário específico
curl "$BASE/HabilitacoesFuncionario?\$filter=userId eq '100052'&\$orderby=dataVencimento asc" -H "$AUTH"

# Certificações vencendo em até 30 dias
curl "$BASE/FuncionariosCertificacoes?\$filter=diasParaVencer le 30 and diasParaVencer ge 0" -H "$AUTH"

# Dashboard geral (todos os departamentos)
curl "$BASE/dashboardArea(departamento='')" -H "$AUTH"

# Dashboard de um departamento específico
curl "$BASE/dashboardArea(departamento='50150001')" -H "$AUTH"

# Todos os tipos de certificação cadastrados
curl "$BASE/TipoCertificacoes?\$orderby=categoria,codigo" -H "$AUTH"

# NR-33 vencidas em qualquer departamento
curl "$BASE/FuncionariosCertificacoes?\$filter=certCodigo eq 'NR-33' and statusCalculado eq 'VENCIDA'" -H "$AUTH"

# Criar nova habilitação
curl -X POST "$BASE/HabilitacoesFuncionario" -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"userId":"100052","nomeCompleto":"Amanda Winters","departamento":"50150001",
       "certificacao_codigo":"NR-33","dataEmissao":"2024-01-15","dataVencimento":"2025-01-15"}'

# Gerar alertas para vencimentos nos próximos 60 dias
curl -X POST "$BASE/gerarAlertas" -H "$AUTH" -H "Content-Type: application/json" \
  -d '{"diasAntecedencia":60}'
```

---

## Ferramentas MCP — Catálogo Completo (15 tools)

O servidor MCP `joule-sfsf-mcp` expõe todas as tools abaixo para o Joule Studio. As tools de certificação (marcadas com **[CAP]**) chamam a API OData V4 da extensão. As demais chamam a API standard do SuccessFactors.

### Employee Central

| Tool | Parâmetros | Fonte de dados |
|---|---|---|
| `listar_funcionarios` | `filtro?: string` | SFSF: `User` |
| `dados_funcionario` | `user_id: string` | SFSF: `User` + `EmpJob` |
| `subordinados_diretos` | `manager_id: string` | SFSF: `EmpJob` + `User` |
| `organograma_departamento` | `dept_code: string` | SFSF: `FODepartment` + `Position` + `EmpJob` |

### Recrutamento

| Tool | Parâmetros | Fonte de dados |
|---|---|---|
| `vagas_internas` | `departamento?: string` | SFSF: `JobRequisition` + `JobRequisitionLocale` |
| `redigir_perfil_vaga` | `job_req_id: string` | SFSF: `JobRequisition` + `JobRequisitionLocale` + `FODepartment` |

### Performance & Desenvolvimento

| Tool | Parâmetros | Fonte de dados |
|---|---|---|
| `avaliacao_desempenho` | `user_id: string` | SFSF: `FormHeader` |
| `metas_funcionario` | `user_id: string` | SFSF: `Goal_1` / `Goal_2` / `Goal_3` |
| `sugerir_metas_gd` | `user_id: string` | SFSF: `User` + `EmpJob` + `FormHeader` |
| `buscar_cursos` | `user_id: string`, `termo?: string` | SFSF: `User` + `UserBadge` |

### Remuneração

| Tool | Parâmetros | Fonte de dados |
|---|---|---|
| `remuneracao_funcionario` | `user_id: string` | SFSF: `EmpPayCompRecurring` + `EmpCompensation` |
| `consultar_remuneracao` | `user_id: string` | SFSF: `User` + `EmpJob` + `EmpPayCompRecurring` + `PayrollRunResult` + `PayrollRunResultItem` |

### Certificações O&G **[CAP]**

| Tool | Parâmetros | Fonte de dados |
|---|---|---|
| `certificacoes_funcionario` | `user_id: string` | CAP: `HabilitacoesFuncionario` |
| `alertas_vencimento` | `dias?: int (padrão 30)` | CAP: `FuncionariosCertificacoes` |
| `dashboard_certificacoes` | `departamento?: string` | CAP: `dashboardArea()` function |

---

## Catálogo de Perguntas — Joule Studio

O Joule pode responder qualquer uma dessas perguntas em linguagem natural. Para cada pergunta está indicado qual tool MCP é acionada e quais dados do SFSF/CAP são consultados.

### Consulta de Colaboradores

| Pergunta ao Joule | Tool acionada | O que retorna |
|---|---|---|
| *"Quem está cadastrado no sistema?"* | `listar_funcionarios` | Lista de até 20 colaboradores com nome, cargo e departamento |
| *"Liste os funcionários do departamento de engenharia"* | `listar_funcionarios(filtro=...)` | Colaboradores filtrados por nome |
| *"Qual o cargo de Kay Holliston?"* | `dados_funcionario('100095')` | Cargo, gestor, centro de custo, grau salarial, avaliação |
| *"Me dê o perfil completo de Amanda Winters"* | `dados_funcionario('100052')` | Todos os dados de emprego: divisão, BU, CC, FTE, data de admissão |
| *"Quem é o gestor de Rick Smolla?"* | `dados_funcionario('100093')` | Campo `gestor` (managerId) |
| *"Qual o centro de custo de Kay Holliston?"* | `dados_funcionario('100095')` | Campo `centroCusto` |
| *"Quando Amanda Winters foi admitida?"* | `dados_funcionario('100052')` | Campo `dataAdmissao` |
| *"Quem são os subordinados de 100083?"* | `subordinados_diretos('100083')` | Lista da equipe direta com cargo e avaliação |
| *"Quantas pessoas a gerente 100095 tem na equipe?"* | `subordinados_diretos('100095')` | Contagem e nomes dos reportes diretos |
| *"Como é o organograma do departamento 50150001?"* | `organograma_departamento('50150001')` | Posições, colaboradores e hierarquia do departamento |
| *"Quais posições existem no departamento de E&P?"* | `organograma_departamento(...)` | Lista de posições abertas e ocupadas |

### Recrutamento

| Pergunta ao Joule | Tool acionada | O que retorna |
|---|---|---|
| *"Quais vagas estão abertas?"* | `vagas_internas()` | Todas as requisições abertas com título, local e prazo |
| *"Tem vagas abertas em Exploração?"* | `vagas_internas('departamento=...')` | Vagas filtradas por departamento |
| *"Quais vagas têm mais de uma vaga disponível?"* | `vagas_internas()` | Lista completa — Joule filtra as com `openings > 1` |
| *"Redija o perfil da vaga 3"* | `redigir_perfil_vaga('3')` | Dados da vaga → Joule gera JD completo em PT-BR com seções estruturadas |
| *"Crie um Job Description para a requisição 26"* | `redigir_perfil_vaga('26')` | JD com Sobre a Oportunidade, Responsabilidades, Requisitos, Benefícios |
| *"Qual a descrição da vaga de gerente de operações?"* | `redigir_perfil_vaga(id)` | Título, departamento, local, prazo e descrição atual |

### Performance & Desenvolvimento

| Pergunta ao Joule | Tool acionada | O que retorna |
|---|---|---|
| *"Como foi a avaliação de Amanda Winters?"* | `avaliacao_desempenho('100052')` | Histórico de formulários com nota, período e avaliador |
| *"Qual a nota de desempenho de Kay Holliston?"* | `avaliacao_desempenho('100095')` | Rating da última avaliação |
| *"Quais as metas de Rick Smolla?"* | `metas_funcionario('100093')` | Metas com indicador, peso, status e prazo |
| *"Quantas metas de Amanda estão 'At Risk'?"* | `metas_funcionario('100052')` | Resumo por status (on_track / at_risk / in_progress) |
| *"Sugira metas SMART para Amanda Winters"* | `sugerir_metas_gd('100052')` | Perfil + avaliação → Joule propõe 4 metas por categoria (Resultado, Técnico, Liderança, Inovação) |
| *"Crie metas de GD para Kay Holliston focadas em liderança"* | `sugerir_metas_gd('100095')` | Metas contextualizadas com cargo e área de O&G |
| *"Quais cursos Kay Holliston deveria fazer?"* | `buscar_cursos('100095')` | Perfil + badges → Joule sugere 5 cursos com plataforma e justificativa |
| *"Sugira cursos de segurança offshore para Amanda"* | `buscar_cursos('100052', 'segurança offshore')` | Recomendações focadas no tema solicitado |
| *"O que Rick Smolla precisa estudar para crescer na carreira?"* | `buscar_cursos('100093')` | Sugestões alinhadas ao cargo e setor de O&G |

### Remuneração

| Pergunta ao Joule | Tool acionada | O que retorna |
|---|---|---|
| *"Qual o salário de Kay Holliston?"* | `remuneracao_funcionario('100095')` | Componentes salariais recorrentes (base, bônus fixo, benefícios) |
| *"Mostre o demonstrativo de Amanda Winters"* | `consultar_remuneracao('100052')` | Salário + pagamentos avulsos + histórico de folhas processadas |
| *"Qual o total mensal de Rick Smolla?"* | `remuneracao_funcionario('100093')` | Soma dos componentes + moeda |
| *"Quando foi a última folha processada para Amanda?"* | `consultar_remuneracao('100052')` | Último `PayrollRunResult` com data de processamento |
| *"Quais os componentes de remuneração de Kay?"* | `remuneracao_funcionario('100095')` | Lista detalhada por `payComponent` com valores |

### Certificações Técnicas O&G (via extensão CAP)

| Pergunta ao Joule | Tool acionada | O que retorna |
|---|---|---|
| *"Quais certificações de Amanda Winters estão vencidas?"* | `certificacoes_funcionario('100052')` | Lista filtrada por `statusCalculado = VENCIDA` |
| *"Amanda tem NR-33 válida?"* | `certificacoes_funcionario('100052')` | Status específico da NR-33 com dias restantes |
| *"Quando vence a NR-35 de Kay Holliston?"* | `certificacoes_funcionario('100095')` | `dataVencimento` e `diasParaVencer` da NR-35 |
| *"Mostre todas as certificações de Rick Smolla"* | `certificacoes_funcionario('100093')` | Lista completa com status de cada habilitação |
| *"Rick pode trabalhar em espaço confinado?"* | `certificacoes_funcionario('100093')` | Verifica NR-33 — Joule interpreta se está vigente |
| *"Quem tem certificação vencida?"* | `alertas_vencimento(dias=0)` | Colaboradores com `statusCalculado = VENCIDA` |
| *"Quem vence certificação nos próximos 30 dias?"* | `alertas_vencimento(dias=30)` | Lista ordenada por urgência com nome, cert. e data |
| *"Quem precisa renovar certificação urgentemente?"* | `alertas_vencimento(dias=7)` | Casos críticos (≤ 7 dias ou já vencidos) |
| *"Quem tem NR-33 a vencer nos próximos 90 dias?"* | `alertas_vencimento(dias=90)` | Joule filtra por certificação no resultado |
| *"Como está o compliance de certificações da empresa?"* | `dashboard_certificacoes()` | % vigentes / a vencer / vencidas + casos críticos |
| *"Qual o percentual de conformidade do departamento 50150001?"* | `dashboard_certificacoes('50150001')` | Dashboard focado no departamento solicitado |
| *"Quantos colaboradores têm certificação vencida em E&P?"* | `dashboard_certificacoes('50150001')` | `vencidas` do resultado do dashboard |
| *"O departamento de SMS está com compliance em dia?"* | `dashboard_certificacoes(dept_code)` | `percentualCompliance` + alertas críticos da área |

### Perguntas Compostas (Joule combina múltiplas tools)

Algumas perguntas levam o Joule a chamar mais de uma tool em sequência:

| Pergunta ao Joule | Tools acionadas em sequência |
|---|---|
| *"Amanda Winters pode ser escalada para atividade offshore amanhã?"* | `dados_funcionario` → `certificacoes_funcionario` → Joule cruza cargo + certificações (OPITO-BOSIET, HUET) |
| *"Qual o perfil completo de Kay Holliston, incluindo metas e certificações?"* | `dados_funcionario` → `metas_funcionario` → `certificacoes_funcionario` |
| *"Quais membros da equipe do gestor 100083 têm NR-33 vencida?"* | `subordinados_diretos` → `certificacoes_funcionario` (para cada subordinado) |
| *"Sugira metas para Amanda com foco em certificações que ela precisará renovar"* | `sugerir_metas_gd` → `certificacoes_funcionario` |
| *"Prepare um relatório do departamento 50150001: equipe, performance e compliance"* | `organograma_departamento` → `dashboard_certificacoes` → Joule sintetiza |

---

## Tipos de Certificação Suportados

| Código | Nome | Categoria | Validade | Obrigatória Para |
|---|---|---|---|---|
| `NR-10` | Segurança em Instalações Elétricas | NR | 24 meses | E&P, Refinaria, Manutenção |
| `NR-13` | Caldeiras, Vasos de Pressão e Tubulações | NR | 24 meses | Refinaria, Operações |
| `NR-33` | Segurança em Espaços Confinados | NR | 12 meses | E&P, Refinaria, SMS |
| `NR-35` | Trabalho em Altura | NR | 12 meses | E&P, Engenharia, Manutenção |
| `NEBOSH-IGC` | NEBOSH International General Certificate | Internacional | 36 meses | SMS, HSSE, Gestão de Riscos |
| `OPITO-BOSIET` | Basic Offshore Safety & Emergency Training | Internacional | 48 meses | E&P Offshore, Plataformas |
| `HUET` | Helicopter Underwater Escape Training | Internacional | 48 meses | E&P Offshore, Logística |
| `STCW-BST` | STCW Basic Safety Training | Internacional | 60 meses | Logística Naval |
| `CIPA-LIDER` | Liderança de CIPA | Interno | 12 meses | Todos |
| `BRIGADA-INCENDIO` | Brigada de Incêndio | Interno | 12 meses | SMS, Facilities |
| `PRTP` | Plano de Resposta a Emergências Petrobras | Interno | 12 meses | Operações, E&P |

---

## Interface — Fiori Elements

### Tela 1: List Report — Visão Geral de Certificações

![List Report com dados carregados](docs/screenshots/02_list_report_status.png)

A tela principal exibe **todas as habilitações** dos colaboradores com carregamento automático ao abrir. Cada linha mostra:

- **Funcionário** — nome vinculado ao perfil SAP SuccessFactors
- **Departamento** — código do departamento (ex: `50150013` = Quality Assurance US)
- **Certificação** — nome completo da habilitação técnica
- **Categoria** — NR / Internacional / Interno
- **Vencimento** — data de expiração
- **Dias p/ Vencer** — contador em dias (negativo = já vencida)
- **Status** — indicador colorido:
  - 🔴 **VENCIDA** — habilitação expirada, colaborador impedido de atuar
  - 🟡 **VENCER_30** — vence em até 30 dias, ação urgente necessária
  - 🟠 **VENCER_90** — vence entre 31 e 90 dias, planejar renovação
  - 🟢 **VIGENTE** — habilitação válida

**Filtros disponíveis:** Nome do funcionário · Código da certificação · Departamento · Status

### Tela 2: Barra de Filtros e Pesquisa

![Filtros e pesquisa](docs/screenshots/03_filtro_barra_pesquisa.png)

O List Report possui filtros rápidos na barra superior. O botão **"Ajustar filtros"** expande opções adicionais de combinação.

### Tela 3: Tela Inicial

![Tela inicial](docs/screenshots/01_fiori_list_report.png)

Carregamento automático ativado (`initialLoad: true` no manifest). Os dados são carregados imediatamente ao abrir a aplicação.

---

## Como Rodar Localmente

```bash
# 1. Clonar e instalar
git clone https://github.com/marcelofiorito/cap-cert-petrobras
cd cap-cert

# 2. Instalar dependências
npm install

# 3. Rodar com dados locais (SQLite)
cds watch

# 4. Acessar
open http://localhost:4004
```

---

## Deploy no SAP BTP

```bash
# 1. Autenticar no CF
cf login --sso

# 2. Build do MTA
mbt build

# 3. Deploy
cf deploy mta_archives/cap-cert-petrobras_1.0.0.mtar
```

### Serviços BTP necessários

| Serviço | Plano | Nome no CF |
|---|---|---|
| SAP HANA Cloud | `hdi-shared` | `cap-joule-db` |
| XSUAA | `application` | `cap-joule-auth` |
| HTML5 App Repository (host) | `app-host` | `cap-cert-petrobras-html5-repo-host` |
| HTML5 App Repository (runtime) | `app-runtime` | `cap-cert-petrobras-html5-runtime` |
| Destination | `lite` | `cap-joule-destination` |

---

## Estrutura do Projeto

```
cap-cert/
├── app/
│   └── cert-management/          ← Fiori Elements (SAPUI5 1.136)
│       ├── annotations.cds       ← @UI: labels, filtros, criticidade, ValueList
│       └── webapp/manifest.json  ← initialLoad: true
├── approuter/
│   ├── package.json              ← @sap/approuter v16
│   └── xs-app.json               ← Rotas: Fiori → OData → XSUAA
├── db/
│   ├── schema.cds                ← Entidades: TipoCertificacao, HabilitacaoFuncionario, AlertaCertificacao
│   └── data/                     ← CSVs seed: 11 tipos + ~28 habilitações demo
├── srv/
│   ├── cert-service.cds          ← CertService OData V4 (/CertService)
│   └── cert-service.js           ← Handlers: calcStatus, dashboardArea, gerarAlertas
├── docs/screenshots/             ← Capturas de tela da interface
├── mta.yaml                      ← Deploy descriptor BTP CF
└── package.json                  ← v1.0.0
```

---

## Licença

MIT
