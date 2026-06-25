using { petrobras.cert as cert } from '../db/schema';

// ─── Serviço OData V4 — CertService ──────────────────────────────────────────
service CertService @(path: '/CertService') {

  // Catálogo de tipos — leitura para todos, escrita requer admin
  entity TipoCertificacoes      as projection on cert.TipoCertificacao;

  // Habilitações — CRUD completo
  @cds.redirection.target: true
  entity HabilitacoesFuncionario as projection on cert.HabilitacaoFuncionario;

  // View calculada — somente leitura
  @readonly
  entity FuncionariosCertificacoes as projection on cert.FuncionarioCertificacoes;

  // Alertas — somente leitura
  @readonly
  entity AlertasCertificacao    as projection on cert.AlertaCertificacao;

  // ─── Lista estática de status para ValueHelp (dropdown no filtro) ───────────
  @readonly
  entity StatusList {
    key code  : String(15);
        label : String(50);
  }

  // ─── Função: resumo de compliance por departamento ────────────────────────
  function dashboardArea(departamento : String) returns {
    departamento  : String;
    totalFuncionarios : Integer;
    vigentes      : Integer;
    aVencer30     : Integer;
    aVencer90     : Integer;
    vencidas      : Integer;
    percentualCompliance : Decimal(5,2);
    alertasCriticos : array of {
      userId       : String;
      nomeCompleto : String;
      certNome     : String;
      dataVencimento : Date;
      diasParaVencer : Integer;
    };
  };

  // ─── Action: gerar alertas para vencimentos próximos ─────────────────────
  action gerarAlertas(diasAntecedencia : Integer default 30) returns {
    gerados : Integer;
    mensagem : String;
  };
}
