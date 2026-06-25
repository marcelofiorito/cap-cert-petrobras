sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"certmanagement/test/integration/pages/FuncionariosCertificacoesList",
	"certmanagement/test/integration/pages/FuncionariosCertificacoesObjectPage"
], function (JourneyRunner, FuncionariosCertificacoesList, FuncionariosCertificacoesObjectPage) {
    'use strict';

    var runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('certmanagement') + '/test/flpSandbox.html#certmanagement-tile',
        pages: {
			onTheFuncionariosCertificacoesList: FuncionariosCertificacoesList,
			onTheFuncionariosCertificacoesObjectPage: FuncionariosCertificacoesObjectPage
        },
        async: true
    });

    return runner;
});

