namespace petrobras.cert;
using { managed, cuid } from '@sap/cds/common';

// ─── Catálogo de tipos de certificação ───────────────────────────────────────

entity TipoCertificacao {
  key codigo          : String(20);
      nome            : String(200)   not null;
      descricao       : String(1000);
      categoria       : String(50);   // NR / INTERNACIONAL / INTERNO
      obrigatoriaPara : String(300);  // áreas/funções que exigem (texto livre)
      validadeMeses   : Integer       not null default 12;
      orgaoEmissor    : String(200);
      renovavel       : Boolean       default true;
}

// ─── Habilitação por funcionário ─────────────────────────────────────────────

entity HabilitacaoFuncionario : cuid, managed {
  userId          : String(100)   not null;
  nomeCompleto    : String(200);
  departamento    : String(100);
  certificacao    : Association to TipoCertificacao;
  dataEmissao     : Date          not null;
  dataVencimento  : Date          not null;
  statusCalculado : String(15);   // persistido — filtrável via OData
  numeroDoc       : String(100);
  orgaoEmissor    : String(200);
  observacao      : String(500);
  arquivoUrl      : String(500);
}

// ─── View com status calculado no banco (filtrável via OData) ────────────────
// statusCalculado é persistido na entidade base e atualizado pelo handler
// no momento de cada escrita — isso permite filtrar via OData $filter

view FuncionarioCertificacoes as
  select from HabilitacaoFuncionario {
    ID,
    userId,
    nomeCompleto,
    departamento,
    certificacao.codigo       as certCodigo,
    certificacao.nome         as certNome,
    certificacao.categoria    as certCategoria,
    dataEmissao,
    dataVencimento,
    statusCalculado,          // lido do campo persistido — filtrável
    numeroDoc,
    orgaoEmissor,
    0                         as diasParaVencer : Integer,
    0                         as criticality   : Integer
  };

// ─── Alertas gerados automaticamente ─────────────────────────────────────────

entity AlertaCertificacao : cuid {
  habilitacao  : Association to HabilitacaoFuncionario;
  tipo         : String(20) not null; // VENCIDA | VENCER_30 | VENCER_90
  dataAlerta   : DateTime   not null;
  lido         : Boolean    default false;
  userId       : String(100);
  certCodigo   : String(20);
}
