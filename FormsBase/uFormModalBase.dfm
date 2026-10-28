inherited frmFormModalBase: TfrmFormModalBase
  BorderStyle = bsDialog
  Caption = 'Modal Base'
  ClientHeight = 297
  ClientWidth = 492
  Padding.Left = 6
  Padding.Top = 6
  Padding.Right = 6
  Padding.Bottom = 6
  Position = poMainFormCenter
  TextHeight = 15
  object pnlRodape: TPanel
    Left = 6
    Top = 250
    Width = 480
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      480
      41)
    object btnFechar: TButton
      Left = 397
      Top = 8
      Width = 80
      Height = 27
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Fechar'
      ModalResult = 2
      TabOrder = 0
    end
  end
end
