inherited frmFormTabBase: TfrmFormTabBase
  Caption = 'Tab Base'
  Padding.Left = 6
  Padding.Top = 6
  Padding.Right = 6
  Padding.Bottom = 6
  OnClose = FormClose
  TextHeight = 15
  object pnlRodape: TPanel
    Left = 6
    Top = 249
    Width = 611
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      611
      41)
    object btnFechar: TButton
      Left = 528
      Top = 8
      Width = 80
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Fechar'
      TabOrder = 0
      OnClick = btnFecharClick
    end
  end
end
