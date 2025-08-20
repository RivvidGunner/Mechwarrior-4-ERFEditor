object frmMain: TfrmMain
  Left = 733
  Top = 215
  Width = 633
  Height = 439
  Caption = 'ERF Editor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnOpen: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Open ERF'
    TabOrder = 0
    OnClick = btnOpenClick
  end
  object btnSaveText: TButton
    Left = 89
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Save as Text'
    TabOrder = 1
    OnClick = btnSaveTextClick
  end
  object btnSaveERF: TButton
    Left = 170
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Save ERF'
    TabOrder = 2
    OnClick = btnSaveERFClick
  end
  object memoOutput: TMemo
    Left = 8
    Top = 39
    Width = 584
    Height = 353
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object OpenDialog: TOpenDialog
    Filter = 'ERF Files|.erf|All Files|.'
    Left = 248
    Top = 8
  end
  object SaveDialog: TSaveDialog
    Filter = 'Text Files|.txt|ERF Files|.erf|All Files|.*'
    Left = 280
    Top = 8
  end
end
