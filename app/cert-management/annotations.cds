using CertService as service from '../../srv/cert-service';

// ─── Labels em português ──────────────────────────────────────────────────────
annotate service.FuncionariosCertificacoes with {
    userId          @title: 'ID Funcionário';
    nomeCompleto    @title: 'Nome';
    departamento    @title: 'Departamento';
    certCodigo      @title: 'Código';
    certNome        @title: 'Certificação';
    certCategoria   @title: 'Categoria';
    dataEmissao     @title: 'Emissão';
    dataVencimento  @title: 'Vencimento';
    numeroDoc       @title: 'Nº Documento';
    orgaoEmissor    @title: 'Órgão Emissor';
    diasParaVencer  @title: 'Dias p/ Vencer';

    // Status como dropdown com valores fixos
    statusCalculado @title: 'Status'
        @Common.ValueListWithFixedValues: true
        @Common.ValueList: {
            CollectionPath : 'StatusList',
            Parameters     : [
                {
                    $Type             : 'Common.ValueListParameterOut',
                    LocalDataProperty : statusCalculado,
                    ValueListProperty : 'code'
                },
                {
                    $Type             : 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty : 'label'
                }
            ]
        };
}

// ─── Anotações de UI para List Report + Object Page ───────────────────────────
annotate service.FuncionariosCertificacoes with @(

    // Header da tela
    UI.HeaderInfo: {
        TypeName       : 'Certificação',
        TypeNamePlural : 'Certificações',
        Title          : { Value: nomeCompleto },
        Description    : { Value: certNome },
    },

    // Seleção de campos na tabela (List Report)
    UI.LineItem: [
        {
            $Type    : 'UI.DataField',
            Label    : 'Funcionário',
            Value    : nomeCompleto,
        },
        {
            $Type    : 'UI.DataField',
            Label    : 'Departamento',
            Value    : departamento,
        },
        {
            $Type    : 'UI.DataField',
            Label    : 'Certificação',
            Value    : certNome,
        },
        {
            $Type    : 'UI.DataField',
            Label    : 'Categoria',
            Value    : certCategoria,
        },
        {
            $Type    : 'UI.DataField',
            Label    : 'Vencimento',
            Value    : dataVencimento,
        },
        {
            $Type    : 'UI.DataField',
            Label    : 'Dias p/ Vencer',
            Value    : diasParaVencer,
        },
        // Status com cor (criticidade)
        {
            $Type              : 'UI.DataFieldForAnnotation',
            Label              : 'Status',
            Target             : '@UI.DataPoint#Status',
        },
    ],

    // DataPoint para colorir o status
    UI.DataPoint #Status: {
        Value       : statusCalculado,
        Title       : 'Status',
        Criticality : criticality,
    },

    // Filtros padrão na barra de pesquisa
    UI.SelectionFields: [
        nomeCompleto,
        certCodigo,
        departamento,
        statusCalculado,
    ],

    // Object Page — detalhe ao clicar em uma linha
    UI.FieldGroup #Identificacao: {
        $Type: 'UI.FieldGroupType',
        Label: 'Funcionário',
        Data : [
            { Value: userId,       Label: 'ID'          },
            { Value: nomeCompleto, Label: 'Nome'        },
            { Value: departamento, Label: 'Departamento'},
        ],
    },

    UI.FieldGroup #Certificacao: {
        $Type: 'UI.FieldGroupType',
        Label: 'Certificação',
        Data : [
            { Value: certCodigo,    Label: 'Código'   },
            { Value: certNome,      Label: 'Nome'     },
            { Value: certCategoria, Label: 'Categoria'},
        ],
    },

    UI.FieldGroup #Validade: {
        $Type: 'UI.FieldGroupType',
        Label: 'Validade',
        Data : [
            { Value: dataEmissao,     Label: 'Emissão'       },
            { Value: dataVencimento,  Label: 'Vencimento'    },
            { Value: diasParaVencer,  Label: 'Dias p/ Vencer'},
            { Value: statusCalculado, Label: 'Status'        },
            { Value: orgaoEmissor,    Label: 'Órgão Emissor' },
            { Value: numeroDoc,       Label: 'Nº Documento'  },
        ],
    },

    UI.Facets: [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'Identificacao',
            Label : 'Funcionário',
            Target: '@UI.FieldGroup#Identificacao',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'Certificacao',
            Label : 'Certificação',
            Target: '@UI.FieldGroup#Certificacao',
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'Validade',
            Label : 'Validade & Documentação',
            Target: '@UI.FieldGroup#Validade',
        },
    ],
);

// ─── Criticidade calculada no handler JS (cert-service.js) ───────────────────
// Fiori: 1=Error(vermelho) 2=Warning(laranja) 3=Success(verde) 0=None
// O campo criticality está definido na view FuncionarioCertificacoes (db/schema.cds)
// e preenchido pelo handler after READ de FuncionariosCertificacoes

