'use strict';
const cds = require('@sap/cds');

module.exports = class CertService extends cds.ApplicationService {

  async init() {

    // ─── Helper: calcular status a partir da data de vencimento ──────────
    const calcStatus = (dataVencimento) => {
      if (!dataVencimento) return { status: 'VIGENTE', diff: 0, crit: 0 };
      const diff = Math.round((new Date(dataVencimento) - new Date()) / 86400000);
      if (diff < 0)        return { status: 'VENCIDA',   diff, crit: 1 };
      if (diff <= 30)      return { status: 'VENCER_30', diff, crit: 2 };
      if (diff <= 90)      return { status: 'VENCER_90', diff, crit: 2 };
      return                      { status: 'VIGENTE',   diff, crit: 3 };
    };

    // ─── Preencher diasParaVencer e criticality ao ler (não persiste) ─────
    const calcularStatus = rows => {
      for (const row of (Array.isArray(rows) ? rows : [rows])) {
        const { status, diff, crit } = calcStatus(row.dataVencimento);
        row.diasParaVencer  = diff;
        row.criticality     = crit;
        // statusCalculado já vem do banco — só recalcula diasParaVencer/criticality
        if (!row.statusCalculado) row.statusCalculado = status;
      }
    };

    // ─── Persistir statusCalculado antes de salvar ───────────────────────
    const persistirStatus = req => {
      const data = req.data;
      if (data.dataVencimento) {
        data.statusCalculado = calcStatus(data.dataVencimento).status;
      }
    };

    this.before('CREATE', 'HabilitacoesFuncionario', persistirStatus);
    this.before('UPDATE', 'HabilitacoesFuncionario', persistirStatus);

    this.after('READ', 'HabilitacoesFuncionario',   calcularStatus);
    this.after('READ', 'FuncionariosCertificacoes', calcularStatus);

    // ─── dashboardArea ────────────────────────────────────────────────────
    this.on('dashboardArea', async ({ data: { departamento } }) => {
      const { HabilitacoesFuncionario } = this.entities;

      const where = departamento ? { departamento } : {};
      const all   = await SELECT.from(HabilitacoesFuncionario).where(where);

      // statusCalculado já vem do banco — só recalcula diasParaVencer
      const rows = all.map(row => {
        const { status, diff } = calcStatus(row.dataVencimento);
        return { ...row,
          statusCalculado: row.statusCalculado || status,
          diasParaVencer: diff
        };
      });

      const userSet  = new Set(rows.map(r => r.userId));
      const vigentes = rows.filter(r => r.statusCalculado === 'VIGENTE').length;
      const v30      = rows.filter(r => r.statusCalculado === 'VENCER_30').length;
      const v90      = rows.filter(r => r.statusCalculado === 'VENCER_90').length;
      const vencidas = rows.filter(r => r.statusCalculado === 'VENCIDA').length;
      const total    = userSet.size;
      const semProblema = new Set(
        rows.filter(r => r.statusCalculado === 'VIGENTE').map(r => r.userId)
      ).size;
      const pct = total > 0 ? Math.round((semProblema / total) * 10000) / 100 : 0;

      const criticos = rows
        .filter(r => ['VENCIDA', 'VENCER_30'].includes(r.statusCalculado))
        .sort((a, b) => a.diasParaVencer - b.diasParaVencer)
        .slice(0, 10)
        .map(r => ({
          userId         : r.userId,
          nomeCompleto   : r.nomeCompleto,
          certCodigo     : r.certificacao_codigo,
          dataVencimento : r.dataVencimento,
          diasParaVencer : r.diasParaVencer,
        }));

      return {
        departamento          : departamento || 'Todos',
        totalFuncionarios     : total,
        vigentes,
        aVencer30             : v30,
        aVencer90             : v90,
        vencidas,
        percentualCompliance  : pct,
        alertasCriticos       : criticos,
      };
    });

    // ─── gerarAlertas ─────────────────────────────────────────────────────
    this.on('gerarAlertas', async ({ data: { diasAntecedencia = 30 } }) => {
      const { FuncionariosCertificacoes, AlertasCertificacao } = this.entities;
      const hoje = new Date().toISOString().split('T')[0];

      const prestes = await SELECT.from(FuncionariosCertificacoes)
        .where(`diasParaVencer <= ${diasAntecedencia}`);

      let gerados = 0;
      for (const row of prestes) {
        const tipo = row.statusCalculado === 'VENCIDA' ? 'VENCIDA' : 'VENCER_30';
        // Evita duplicatas — verifica se alerta do dia já existe
        const existing = await SELECT.one.from(AlertasCertificacao)
          .where({
            habilitacao_ID : row.ID,
            tipo,
            lido           : false,
          });
        if (!existing) {
          await INSERT.into(AlertasCertificacao).entries({
            habilitacao_ID : row.ID,
            tipo,
            dataAlerta     : new Date().toISOString(),
            lido           : false,
            userId         : row.userId,
            certCodigo     : row.certCodigo,
          });
          gerados++;
        }
      }

      return {
        gerados,
        mensagem: `${gerados} alertas gerados para certificações vencendo em ${diasAntecedencia} dias.`,
      };
    });

    await super.init();
  }
};
