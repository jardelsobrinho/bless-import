inherited frmHistorico: TfrmHistorico
  Caption = 'Hist'#243'rico de importa'#231#245'es'
  ClientHeight = 600
  ClientWidth = 1100
  OnCreate = FormCreate
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 553
    Width = 1088
    DesignSize = (
      1088
      41)
    inherited btnFechar: TButton
      Left = 1005
    end
  end
  object pnlFiltros: TPanel
    Left = 6
    Top = 6
    Width = 1088
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblPerfil: TLabel
      Left = 0
      Top = 12
      Width = 33
      Height = 15
      Caption = 'Perfil:'
    end
    object cbxPerfil: TComboBox
      Left = 44
      Top = 9
      Width = 320
      Height = 23
      Style = csDropDownList
      DropDownCount = 20
      TabOrder = 0
      OnChange = cbxPerfilChange
    end
    object btnAtualizar: TButton
      Left = 376
      Top = 7
      Width = 90
      Height = 27
      Caption = 'Atualizar'
      TabOrder = 1
      OnClick = btnAtualizarClick
    end
    object btnRetomar: TButton
      Left = 480
      Top = 7
      Width = 160
      Height = 27
      Hint =
        'Continua uma importa'#231#227'o interrompida, cancelada ou que falhou a ' +
        'partir da '#250'ltima linha gravada'
      Caption = 'Retomar importa'#231#227'o'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = btnRetomarClick
    end
  end
  object grdExecucoes: TDBGrid
    Left = 6
    Top = 47
    Width = 1088
    Height = 280
    Align = alTop
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    OnDrawColumnCell = grdExecucoesDrawColumnCell
    Columns = <
      item
        Expanded = False
        FieldName = 'ID'
        Title.Caption = 'Execu'#231#227'o'
        Width = 60
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PERFIL'
        Title.Caption = 'Perfil'
        Width = 160
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'INICIO'
        Title.Caption = 'In'#237'cio'
        Width = 120
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FIM'
        Title.Caption = 'Fim'
        Width = 120
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'SITUACAO'
        Title.Caption = 'Situa'#231#227'o'
        Width = 150
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ESTRATEGIA'
        Title.Caption = 'Estrat'#233'gia'
        Width = 130
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'LINHAS_LIDAS'
        Title.Caption = 'Lidas'
        Width = 55
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'INSERIDAS'
        Title.Caption = 'Inseridas'
        Width = 60
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ATUALIZADAS'
        Title.Caption = 'Atualizadas'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IGNORADAS'
        Title.Caption = 'Ignoradas'
        Width = 65
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALIDADAS'
        Title.Caption = 'Validadas'
        Width = 62
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'COM_ERRO'
        Title.Caption = 'Com erro'
        Width = 62
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'LINHA_INICIO'
        Title.Caption = 'Da linha'
        Width = 58
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ULTIMA_LINHA'
        Title.Caption = 'At'#233' a linha'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ID_EXECUCAO_ORIGEM'
        Title.Caption = 'Retoma a'
        Width = 62
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'MENSAGEM'
        Title.Caption = 'Mensagem'
        Width = 400
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ARQUIVO'
        Title.Caption = 'Planilha'
        Width = 300
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CONEXAO'
        Title.Caption = 'Destino'
        Width = 250
        Visible = True
      end>
  end
  object splErros: TSplitter
    Left = 6
    Top = 327
    Width = 1088
    Height = 4
    Cursor = crVSplit
    Align = alTop
  end
  object pnlErros: TPanel
    Left = 6
    Top = 331
    Width = 1088
    Height = 222
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object lblErros: TLabel
      Left = 0
      Top = 0
      Width = 1088
      Height = 15
      Align = alTop
      Caption = 'Erros'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object grdErros: TDBGrid
      Left = 0
      Top = 15
      Width = 1088
      Height = 207
      Align = alClient
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgCancelOnExit]
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -12
      TitleFont.Name = 'Segoe UI'
      TitleFont.Style = []
      Columns = <
        item
          Expanded = False
          FieldName = 'LINHA'
          Title.Caption = 'Linha'
          Width = 50
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'CAMPO'
          Title.Caption = 'Campo'
          Width = 160
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TIPO'
          Title.Caption = 'Tipo de erro'
          Width = 100
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VALOR_RECEBIDO'
          Title.Caption = 'Valor recebido'
          Width = 200
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'MENSAGEM'
          Title.Caption = 'Mensagem'
          Width = 600
          Visible = True
        end>
    end
  end
end
