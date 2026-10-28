inherited frmImportacao: TfrmImportacao
  Caption = 'Importa'#231#227'o'
  ClientHeight = 640
  ClientWidth = 1200
  OnCreate = FormCreate
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 593
    Width = 1188
    DesignSize = (
      1188
      41)
    inherited btnFechar: TButton
      Left = 1105
    end
  end
  object pnlTopo: TPanel
    Left = 6
    Top = 6
    Width = 1188
    Height = 128
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblPerfil: TLabel
      Left = 0
      Top = 11
      Width = 33
      Height = 15
      Caption = 'Perfil:'
    end
    object lblPlanilha: TLabel
      Left = 0
      Top = 43
      Width = 48
      Height = 15
      Caption = 'Planilha:'
    end
    object lblLinhas: TLabel
      Left = 760
      Top = 11
      Width = 92
      Height = 15
      Caption = 'Linhas na pr'#233'via:'
    end
    object lblTodas: TLabel
      Left = 940
      Top = 11
      Width = 61
      Height = 15
      Caption = '(0 = todas)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblResumo: TLabel
      Left = 0
      Top = 106
      Width = 3
      Height = 15
    end
    object cbxPerfil: TComboBox
      Left = 70
      Top = 8
      Width = 400
      Height = 23
      Style = csDropDownList
      DropDownCount = 20
      TabOrder = 0
      OnChange = cbxPerfilChange
      OnDropDown = cbxPerfilDropDown
    end
    object edtPlanilha: TEdit
      Left = 70
      Top = 40
      Width = 640
      Height = 23
      TabOrder = 1
    end
    object btnProcurar: TButton
      Left = 714
      Top = 39
      Width = 30
      Height = 25
      Hint = 'Escolher a planilha'
      Caption = '...'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = btnProcurarClick
    end
    object edtLinhas: TEdit
      Left = 860
      Top = 8
      Width = 55
      Height = 23
      NumbersOnly = True
      TabOrder = 3
      Text = '100'
    end
    object udLinhas: TUpDown
      Left = 915
      Top = 8
      Width = 16
      Height = 23
      Associate = edtLinhas
      Max = 100000
      Increment = 100
      Position = 100
      TabOrder = 4
      Thousands = False
    end
    object btnValidar: TButton
      Left = 760
      Top = 38
      Width = 130
      Height = 27
      Caption = 'Validar perfil'
      TabOrder = 5
      OnClick = btnValidarClick
    end
    object btnPreVisualizar: TButton
      Left = 896
      Top = 38
      Width = 130
      Height = 27
      Caption = 'Pr'#233'-visualizar'
      TabOrder = 6
      OnClick = btnPreVisualizarClick
    end
    object btnImportar: TButton
      Left = 1032
      Top = 38
      Width = 130
      Height = 27
      Caption = 'Importar'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
      OnClick = btnImportarClick
    end
    object pbProgresso: TProgressBar
      Left = 70
      Top = 76
      Width = 820
      Height = 20
      TabOrder = 8
      Visible = False
    end
    object btnCancelar: TButton
      Left = 896
      Top = 72
      Width = 130
      Height = 27
      Caption = 'Cancelar'
      TabOrder = 9
      Visible = False
      OnClick = btnCancelarClick
    end
    object lblRetomada: TLabel
      Left = 70
      Top = 78
      Width = 3
      Height = 15
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Visible = False
    end
    object btnNaoRetomar: TButton
      Left = 896
      Top = 72
      Width = 130
      Height = 27
      Hint = 'Importar a planilha desde o come'#231'o, como uma importa'#231#227'o nova'
      Caption = 'N'#227'o retomar'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 10
      Visible = False
      OnClick = btnNaoRetomarClick
    end
  end
  object pcResultado: TPageControl
    Left = 6
    Top = 134
    Width = 1188
    Height = 459
    ActivePage = tabPrevia
    Align = alClient
    TabOrder = 2
    object tabProblemas: TTabSheet
      Caption = 'Problemas do perfil'
      object grdProblemas: TStringGrid
        Left = 0
        Top = 0
        Width = 1180
        Height = 453
        Align = alClient
        ColCount = 3
        DefaultRowHeight = 22
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        TabOrder = 0
        OnDrawCell = grdProblemasDrawCell
        ColWidths = (
          70
          180
          900)
      end
    end
    object tabPrevia: TTabSheet
      Caption = 'Pr'#233'-visualiza'#231#227'o'
      ImageIndex = 1
      object pnlLegenda: TPanel
        Left = 0
        Top = 0
        Width = 1180
        Height = 28
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object lblLegenda: TLabel
          Left = 4
          Top = 6
          Width = 92
          Height = 15
          Caption = 'Origem do valor:'
        end
        object lblLegendaPlanilha: TLabel
          Left = 104
          Top = 4
          Width = 80
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Planilha'
          Layout = tlCenter
          Transparent = False
        end
        object lblLegendaFixo: TLabel
          Left = 190
          Top = 4
          Width = 80
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Valor fixo'
          Layout = tlCenter
          Transparent = False
        end
        object lblLegendaPadrao: TLabel
          Left = 276
          Top = 4
          Width = 90
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Valor padr'#227'o'
          Layout = tlCenter
          Transparent = False
        end
        object lblLegendaExpressao: TLabel
          Left = 372
          Top = 4
          Width = 80
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Express'#227'o'
          Layout = tlCenter
          Transparent = False
        end
        object lblLegendaConsulta: TLabel
          Left = 458
          Top = 4
          Width = 80
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Consulta'
          Layout = tlCenter
          Transparent = False
        end
        object lblLegendaGerado: TLabel
          Left = 544
          Top = 4
          Width = 80
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Gerado'
          Layout = tlCenter
          Transparent = False
        end
        object lblLegendaErro: TLabel
          Left = 630
          Top = 4
          Width = 80
          Height = 19
          Alignment = taCenter
          AutoSize = False
          Caption = 'Erro'
          Layout = tlCenter
          Transparent = False
        end
      end
      object grdPrevia: TStringGrid
        Left = 0
        Top = 28
        Width = 1180
        Height = 335
        Align = alClient
        ColCount = 2
        DefaultRowHeight = 22
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing]
        TabOrder = 1
        OnDrawCell = grdPreviaDrawCell
        OnSelectCell = grdPreviaSelectCell
        ColWidths = (
          50
          80)
      end
      object mmoDetalhe: TMemo
        Left = 0
        Top = 363
        Width = 1180
        Height = 90
        Align = alBottom
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 2
      end
    end
    object tabErros: TTabSheet
      Caption = 'Erros'
      ImageIndex = 2
      object grdErros: TStringGrid
        Left = 0
        Top = 0
        Width = 1180
        Height = 453
        Align = alClient
        ColCount = 5
        DefaultRowHeight = 22
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goRowSelect]
        TabOrder = 0
        Hint = 'Duplo clique: mostra o erro na pr'#233'-visualiza'#231#227'o'
        ParentShowHint = False
        ShowHint = True
        OnDblClick = grdErrosDblClick
        ColWidths = (
          50
          160
          100
          200
          650)
      end
    end
  end
  object dlgAbrir: TOpenDialog
    Filter = 'Planilhas do Excel (*.xls;*.xlsx)|*.xls;*.xlsx|Todos os arquivos (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Title = 'Planilha a importar'
    Left = 1120
    Top = 24
  end
end
