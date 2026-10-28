inherited frmConexoes: TfrmConexoes
  Caption = 'Conex'#245'es'
  ClientHeight = 450
  ClientWidth = 900
  OnCreate = FormCreate
  TextHeight = 15
  inherited pnlRodape: TPanel
    Top = 403
    Width = 888
    DesignSize = (
      888
      41)
    inherited btnFechar: TButton
      Left = 805
    end
  end
  object pnlBotoes: TPanel
    Left = 6
    Top = 6
    Width = 888
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btnNovo: TButton
      Left = 0
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Novo'
      TabOrder = 0
      OnClick = btnNovoClick
    end
    object btnEditar: TButton
      Left = 96
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Editar'
      TabOrder = 1
      OnClick = btnEditarClick
    end
    object btnExcluir: TButton
      Left = 192
      Top = 6
      Width = 90
      Height = 27
      Caption = 'Excluir'
      TabOrder = 2
      OnClick = btnExcluirClick
    end
    object btnTestar: TButton
      Left = 304
      Top = 6
      Width = 120
      Height = 27
      Caption = 'Testar conex'#227'o'
      TabOrder = 3
      OnClick = btnTestarClick
    end
  end
  object grdConexoes: TDBGrid
    Left = 6
    Top = 47
    Width = 888
    Height = 356
    Align = alClient
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ReadOnly = True
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
    OnDblClick = grdConexoesDblClick
    Columns = <
      item
        Expanded = False
        FieldName = 'NOME'
        Title.Caption = 'Nome'
        Width = 180
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ERP'
        Width = 80
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'SERVIDOR'
        Title.Caption = 'Servidor'
        Width = 120
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PORTA'
        Title.Caption = 'Porta'
        Width = 50
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BANCO'
        Title.Caption = 'Banco'
        Width = 220
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'USUARIO'
        Title.Caption = 'Usu'#225'rio'
        Width = 80
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CHARSET'
        Title.Caption = 'Charset'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DIALETO'
        Title.Caption = 'Dialeto'
        Width = 50
        Visible = True
      end>
  end
end
