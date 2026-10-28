inherited frmPerfilEdicao: TfrmPerfilEdicao
  BorderStyle = bsSizeable
  Caption = 'Perfil de importa'#231#227'o'
  ClientHeight = 760
  ClientWidth = 1240
  Constraints.MinHeight = 600
  Constraints.MinWidth = 1000
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  ExplicitWidth = 1252
  ExplicitHeight = 798
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 713
    Width = 1228
    TabOrder = 1
    ExplicitTop = 712
    ExplicitWidth = 1224
    DesignSize = (
      1228
      41)
    object lblResumo: TLabel [0]
      Left = 184
      Top = 14
      Width = 3
      Height = 15
    end
    inherited btnFechar: TButton
      Left = 1145
      Caption = 'Cancelar'
      TabOrder = 2
      ExplicitLeft = 1141
    end
    object btnGravar: TButton
      Left = 1059
      Top = 8
      Width = 80
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Gravar'
      TabOrder = 1
      OnClick = btnGravarClick
      ExplicitLeft = 1055
    end
    object btnSugerir: TButton
      Left = 0
      Top = 8
      Width = 170
      Height = 27
      Hint = 'Mapeia os campos ainda n'#227'o mapeados para a coluna de mesmo nome'
      Caption = 'Sugerir mapeamento'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = btnSugerirClick
    end
  end
  object pnlPerfil: TPanel
    Left = 6
    Top = 6
    Width = 1228
    Height = 136
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 1224
    object lblNome: TLabel
      Left = 0
      Top = 11
      Width = 36
      Height = 15
      Caption = 'Nome:'
    end
    object lblDescricao: TLabel
      Left = 430
      Top = 11
      Width = 54
      Height = 15
      Caption = 'Descri'#231#227'o:'
    end
    object lblConexao: TLabel
      Left = 0
      Top = 43
      Width = 49
      Height = 15
      Caption = 'Conex'#227'o:'
    end
    object lblTabela: TLabel
      Left = 430
      Top = 43
      Width = 79
      Height = 15
      Caption = 'Tabela destino:'
    end
    object lblInfoTabela: TLabel
      Left = 790
      Top = 43
      Width = 3
      Height = 15
    end
    object lblPlanilha: TLabel
      Left = 0
      Top = 75
      Width = 45
      Height = 15
      Caption = 'Planilha:'
    end
    object lblAba: TLabel
      Left = 0
      Top = 107
      Width = 24
      Height = 15
      Caption = 'Aba:'
    end
    object lblLinhaCabecalho: TLabel
      Left = 310
      Top = 107
      Width = 106
      Height = 15
      Caption = 'Linha do cabe'#231'alho:'
    end
    object lblLinhaInicial: TLabel
      Left = 500
      Top = 107
      Width = 123
      Height = 15
      Caption = 'Linha inicial dos dados:'
    end
    object lblInfoPlanilha: TLabel
      Left = 730
      Top = 107
      Width = 3
      Height = 15
    end
    object edtNome: TEdit
      Left = 90
      Top = 8
      Width = 320
      Height = 23
      MaxLength = 100
      TabOrder = 0
    end
    object edtDescricao: TEdit
      Left = 530
      Top = 8
      Width = 341
      Height = 23
      MaxLength = 500
      TabOrder = 1
    end
    object cbxConexao: TComboBox
      Left = 90
      Top = 40
      Width = 320
      Height = 23
      Style = csDropDownList
      TabOrder = 2
      OnChange = cbxConexaoChange
    end
    object cbxTabela: TComboBox
      Left = 530
      Top = 40
      Width = 341
      Height = 23
      CharCase = ecUpperCase
      Sorted = True
      TabOrder = 3
      OnExit = cbxTabelaExit
      OnSelect = cbxTabelaSelect
    end
    object edtPlanilha: TEdit
      Left = 90
      Top = 72
      Width = 600
      Height = 23
      TabOrder = 4
    end
    object btnProcurar: TButton
      Left = 694
      Top = 71
      Width = 30
      Height = 25
      Hint = 'Escolher a planilha'
      Caption = '...'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      OnClick = btnProcurarClick
    end
    object btnCarregarPlanilha: TButton
      Left = 730
      Top = 70
      Width = 140
      Height = 27
      Caption = 'Carregar planilha'
      TabOrder = 6
      OnClick = btnCarregarPlanilhaClick
    end
    object cbxAba: TComboBox
      Left = 90
      Top = 104
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 7
      OnChange = cbxAbaChange
    end
    object edtLinhaCabecalho: TEdit
      Left = 424
      Top = 104
      Width = 45
      Height = 23
      NumbersOnly = True
      TabOrder = 8
      Text = '1'
      OnChange = edtLinhaChange
    end
    object udLinhaCabecalho: TUpDown
      Left = 469
      Top = 104
      Width = 16
      Height = 23
      Associate = edtLinhaCabecalho
      Max = 1000
      Position = 1
      TabOrder = 9
    end
    object edtLinhaInicial: TEdit
      Left = 631
      Top = 104
      Width = 45
      Height = 23
      NumbersOnly = True
      TabOrder = 10
      Text = '2'
      OnChange = edtLinhaChange
    end
    object udLinhaInicial: TUpDown
      Left = 676
      Top = 104
      Width = 16
      Height = 23
      Associate = edtLinhaInicial
      Min = 1
      Max = 1000
      Position = 2
      TabOrder = 11
    end
  end
  object pcPrincipal: TPageControl
    Left = 6
    Top = 142
    Width = 1228
    Height = 571
    ActivePage = tsBancoDestino
    Align = alClient
    TabOrder = 2
    object tsBancoDestino: TTabSheet
      Caption = 'Tabela de Destino'
      object splDetalhe: TSplitter
        Left = 787
        Top = 0
        Height = 541
        Align = alRight
        ExplicitLeft = 0
        ExplicitHeight = 163
      end
      object grdCampos: TStringGrid
        Left = 0
        Top = 0
        Width = 787
        Height = 541
        Align = alClient
        ColCount = 7
        DefaultRowHeight = 22
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        TabOrder = 0
        OnClick = grdCamposClick
        OnDrawCell = grdCamposDrawCell
        ExplicitLeft = 5
        ExplicitTop = -2
        ColWidths = (
          170
          120
          45
          150
          180
          170
          160)
      end
      object pnlDetalhe: TPanel
        Left = 790
        Top = 0
        Width = 430
        Height = 541
        Align = alRight
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitLeft = 878
        ExplicitTop = 136
        object lblCampo: TLabel
          Left = 8
          Top = 4
          Width = 3
          Height = 15
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblCampoInfo: TLabel
          Left = 8
          Top = 24
          Width = 3
          Height = 15
        end
        object lblOrigem: TLabel
          Left = 8
          Top = 53
          Width = 89
          Height = 15
          Caption = 'Origem do valor:'
        end
        object cbxOrigem: TComboBox
          Left = 130
          Top = 50
          Width = 290
          Height = 23
          Style = csDropDownList
          DropDownCount = 10
          TabOrder = 0
          OnChange = OpcaoChange
        end
        object pnlColuna: TPanel
          Left = 0
          Top = 82
          Width = 430
          Height = 32
          BevelOuter = bvNone
          TabOrder = 1
          object lblColuna: TLabel
            Left = 8
            Top = 7
            Width = 41
            Height = 15
            Caption = 'Coluna:'
          end
          object cbxColuna: TComboBox
            Left = 130
            Top = 4
            Width = 290
            Height = 23
            DropDownCount = 20
            TabOrder = 0
            OnChange = OpcaoChange
          end
        end
        object pnlFixo: TPanel
          Left = 0
          Top = 114
          Width = 430
          Height = 32
          BevelOuter = bvNone
          TabOrder = 2
          object lblValorFixo: TLabel
            Left = 8
            Top = 7
            Width = 51
            Height = 15
            Caption = 'Valor fixo:'
          end
          object edtValorFixo: TEdit
            Left = 130
            Top = 4
            Width = 290
            Height = 23
            TabOrder = 0
            OnChange = OpcaoChange
          end
        end
        object pnlPadrao: TPanel
          Left = 0
          Top = 146
          Width = 430
          Height = 84
          BevelOuter = bvNone
          TabOrder = 3
          object lblValorPadrao: TLabel
            Left = 8
            Top = 7
            Width = 69
            Height = 15
            Caption = 'Valor padr'#227'o:'
          end
          object lblUsarPadrao: TLabel
            Left = 8
            Top = 35
            Width = 168
            Height = 15
            Caption = 'Usar o padr'#227'o quando a coluna:'
          end
          object edtValorPadrao: TEdit
            Left = 130
            Top = 4
            Width = 290
            Height = 23
            TabOrder = 0
            OnChange = OpcaoChange
          end
          object chkSeInexistente: TCheckBox
            Left = 20
            Top = 56
            Width = 110
            Height = 19
            Caption = 'n'#227'o existir'
            TabOrder = 1
            OnClick = OpcaoChange
          end
          object chkSeVazio: TCheckBox
            Left = 140
            Top = 56
            Width = 110
            Height = 19
            Caption = 'estiver vazia'
            TabOrder = 2
            OnClick = OpcaoChange
          end
          object chkSeInvalido: TCheckBox
            Left = 260
            Top = 56
            Width = 160
            Height = 19
            Hint = 'Quando o valor n'#227'o puder ser transformado (ex.: data inv'#225'lida)'
            Caption = 'tiver valor inv'#225'lido'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 3
            OnClick = OpcaoChange
          end
        end
        object pnlGerado: TPanel
          Left = 0
          Top = 230
          Width = 430
          Height = 32
          BevelOuter = bvNone
          TabOrder = 4
          object lblGenerator: TLabel
            Left = 8
            Top = 7
            Width = 55
            Height = 15
            Caption = 'Generator:'
          end
          object cbxGenerator: TComboBox
            Left = 130
            Top = 4
            Width = 290
            Height = 23
            CharCase = ecUpperCase
            DropDownCount = 20
            Sorted = True
            TabOrder = 0
            OnChange = OpcaoChange
          end
        end
        object pnlExpressao: TPanel
          Left = 0
          Top = 262
          Width = 430
          Height = 52
          BevelOuter = bvNone
          TabOrder = 5
          object lblExpressao: TLabel
            Left = 8
            Top = 7
            Width = 54
            Height = 15
            Caption = 'Express'#227'o:'
          end
          object lblAjudaExpressao: TLabel
            Left = 130
            Top = 30
            Width = 185
            Height = 15
            Caption = 'Ex.: {Endereco}, {Numero} - {Bairro}'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object edtExpressao: TEdit
            Left = 130
            Top = 4
            Width = 290
            Height = 23
            TabOrder = 0
            OnChange = OpcaoChange
          end
        end
        object pnlConsulta: TPanel
          Left = 0
          Top = 314
          Width = 430
          Height = 124
          BevelOuter = bvNone
          TabOrder = 6
          object lblConsultaTabela: TLabel
            Left = 8
            Top = 7
            Width = 88
            Height = 15
            Caption = 'Pesquisar tabela:'
          end
          object lblConsultaPesquisa: TLabel
            Left = 8
            Top = 35
            Width = 66
            Height = 15
            Caption = 'Pelo campo:'
          end
          object lblConsultaRetorno: TLabel
            Left = 8
            Top = 63
            Width = 98
            Height = 15
            Caption = 'Retornar o campo:'
          end
          object lblConsultaSeNaoAchar: TLabel
            Left = 8
            Top = 91
            Width = 92
            Height = 15
            Caption = 'Se n'#227'o encontrar:'
          end
          object cbxConsultaTabela: TComboBox
            Left = 130
            Top = 4
            Width = 290
            Height = 23
            CharCase = ecUpperCase
            DropDownCount = 20
            Sorted = True
            TabOrder = 0
            OnChange = OpcaoChange
          end
          object edtConsultaPesquisa: TEdit
            Left = 130
            Top = 32
            Width = 290
            Height = 23
            CharCase = ecUpperCase
            TabOrder = 1
            OnChange = OpcaoChange
          end
          object edtConsultaRetorno: TEdit
            Left = 130
            Top = 60
            Width = 290
            Height = 23
            CharCase = ecUpperCase
            TabOrder = 2
            OnChange = OpcaoChange
          end
          object cbxConsultaSeNaoAchar: TComboBox
            Left = 130
            Top = 88
            Width = 290
            Height = 23
            Style = csDropDownList
            TabOrder = 3
            OnChange = OpcaoChange
          end
        end
        object pnlConsultaSql: TPanel
          Left = 0
          Top = 438
          Width = 430
          Height = 180
          BevelOuter = bvNone
          TabOrder = 8
          Visible = False
          object lblConsultaSql: TLabel
            Left = 8
            Top = 4
            Width = 190
            Height = 15
            Caption = 'SELECT (use {Coluna} e {valor}):'
          end
          object lblConsultaSqlSeNaoAchar: TLabel
            Left = 120
            Top = 110
            Width = 93
            Height = 15
            Caption = 'Se n'#227'o encontrar:'
          end
          object lblAjudaConsultaSql: TLabel
            Left = 8
            Top = 136
            Width = 412
            Height = 40
            AutoSize = False
            Caption =
              'O campo recebe a 1'#170' coluna da 1'#170' linha. Ex.: select CODIGO from' +
              ' CIDADE where NOME = {Cidade} and SIGLA_UF = {UF}'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            WordWrap = True
          end
          object mmoConsultaSql: TMemo
            Left = 8
            Top = 22
            Width = 412
            Height = 80
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Consolas'
            Font.Style = []
            ParentFont = False
            ScrollBars = ssVertical
            TabOrder = 0
            OnExit = OpcaoChange
          end
          object btnTestarSql: TButton
            Left = 8
            Top = 106
            Width = 100
            Height = 25
            Hint = 'Executa o SELECT com os valores de exemplo da planilha'
            Caption = 'Testar'
            ParentShowHint = False
            ShowHint = True
            TabOrder = 1
            OnClick = btnTestarSqlClick
          end
          object cbxConsultaSqlSeNaoAchar: TComboBox
            Left = 222
            Top = 106
            Width = 198
            Height = 23
            Style = csDropDownList
            TabOrder = 2
            OnChange = OpcaoChange
          end
        end
        object grpTransformacoes: TGroupBox
          Left = 0
          Top = 313
          Width = 430
          Height = 228
          Align = alBottom
          Caption = ' Transforma'#231#245'es (aplicadas em ordem) '
          TabOrder = 7
          object lblAjudaTransformacao: TLabel
            Left = 8
            Top = 198
            Width = 412
            Height = 30
            AutoSize = False
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clGrayText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            WordWrap = True
          end
          object lblExemplo: TLabel
            Left = 8
            Top = 232
            Width = 412
            Height = 32
            AutoSize = False
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            WordWrap = True
          end
          object lstTransformacoes: TListBox
            Left = 8
            Top = 22
            Width = 300
            Height = 110
            ItemHeight = 15
            TabOrder = 0
            OnClick = lstTransformacoesClick
          end
          object btnSubir: TButton
            Left = 316
            Top = 22
            Width = 100
            Height = 25
            Caption = 'Subir'
            TabOrder = 1
            OnClick = btnSubirClick
          end
          object btnDescer: TButton
            Left = 316
            Top = 52
            Width = 100
            Height = 25
            Caption = 'Descer'
            TabOrder = 2
            OnClick = btnDescerClick
          end
          object btnRemover: TButton
            Left = 316
            Top = 82
            Width = 100
            Height = 25
            Caption = 'Remover'
            TabOrder = 3
            OnClick = btnRemoverClick
          end
          object cbxTipoTransformacao: TComboBox
            Left = 8
            Top = 140
            Width = 300
            Height = 23
            Style = csDropDownList
            DropDownCount = 16
            TabOrder = 4
            OnChange = cbxTipoTransformacaoChange
          end
          object edtParametroTransformacao: TEdit
            Left = 8
            Top = 170
            Width = 300
            Height = 23
            TabOrder = 5
            TextHint = 'Par'#226'metro'
          end
          object btnAdicionarTransformacao: TButton
            Left = 316
            Top = 139
            Width = 100
            Height = 25
            Caption = 'Adicionar'
            TabOrder = 6
            OnClick = btnAdicionarTransformacaoClick
          end
          object btnAlterarTransformacao: TButton
            Left = 316
            Top = 169
            Width = 100
            Height = 25
            Caption = 'Alterar'
            TabOrder = 7
            OnClick = btnAlterarTransformacaoClick
          end
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Planilha de Origem'
      ImageIndex = 1
      object pnlColunas: TPanel
        Left = 0
        Top = 0
        Width = 1220
        Height = 541
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitWidth = 1216
        ExplicitHeight = 540
        object lblColunasPlanilha: TLabel
          Left = 0
          Top = 0
          Width = 1220
          Height = 15
          Align = alTop
          Caption = 'Colunas da planilha'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitWidth = 103
        end
        object chkSoNaoUsadas: TCheckBox
          Left = 0
          Top = 15
          Width = 1220
          Height = 21
          Align = alTop
          Caption = 'Mostrar s'#243' as n'#227'o usadas'
          TabOrder = 0
          OnClick = chkSoNaoUsadasClick
          ExplicitWidth = 1216
        end
        object grdColunas: TStringGrid
          Left = 0
          Top = 36
          Width = 1220
          Height = 505
          Hint = 
            'Duplo clique: usa esta coluna no campo selecionado na grade de c' +
            'ampos'
          Align = alClient
          ColCount = 3
          DefaultRowHeight = 22
          FixedCols = 0
          RowCount = 2
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnDblClick = grdColunasDblClick
          OnDrawCell = grdColunasDrawCell
          ExplicitWidth = 1216
          ExplicitHeight = 504
          ColWidths = (
            130
            60
            120)
        end
      end
    end
    object tsGravacao: TTabSheet
      Caption = 'Grava'#231#227'o'
      ImageIndex = 2
      object lblEstrategia: TLabel
        Left = 16
        Top = 19
        Width = 132
        Height = 15
        Caption = 'Estrat'#233'gia de grava'#231#227'o:'
      end
      object lblAcaoErro: TLabel
        Left = 16
        Top = 51
        Width = 96
        Height = 15
        Caption = 'Em caso de erro:'
      end
      object lblCamposChave: TLabel
        Left = 16
        Top = 83
        Width = 85
        Height = 15
        Caption = 'Campos-chave:'
      end
      object lblAjudaChave: TLabel
        Left = 180
        Top = 83
        Width = 520
        Height = 15
        Caption =
          'Identificam o registro no destino (ex.: CGC). Usados para saber' +
          ' se ele j'#225' existe.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblAjudaEstrategia: TLabel
        Left = 560
        Top = 104
        Width = 520
        Height = 220
        AutoSize = False
        WordWrap = True
      end
      object cbxEstrategia: TComboBox
        Left = 180
        Top = 16
        Width = 360
        Height = 23
        Style = csDropDownList
        TabOrder = 0
        OnChange = cbxEstrategiaChange
      end
      object cbxAcaoErro: TComboBox
        Left = 180
        Top = 48
        Width = 360
        Height = 23
        Style = csDropDownList
        TabOrder = 1
        OnChange = cbxEstrategiaChange
      end
      object clbCamposChave: TCheckListBox
        Left = 180
        Top = 104
        Width = 360
        Height = 380
        Anchors = [akLeft, akTop, akBottom]
        ItemHeight = 17
        TabOrder = 2
      end
    end
  end
  object dlgAbrir: TOpenDialog
    Filter = 
      'Planilhas do Excel (*.xls;*.xlsx)|*.xls;*.xlsx|Todos os arquivos' +
      ' (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Planilha de exemplo'
    Left = 1176
    Top = 16
  end
end
