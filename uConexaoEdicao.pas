unit uConexaoEdicao;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, uFormModalBase, Vcl.StdCtrls, Vcl.ExtCtrls, uConexaoDados,
  uConexoesDm;

type
  TfrmConexaoEdicao = class(TfrmFormModalBase)
    btnGravar: TButton;
    btnTestar: TButton;
    lblNome: TLabel;
    edtNome: TEdit;
    lblErp: TLabel;
    cbxErp: TComboBox;
    lblServidor: TLabel;
    edtServidor: TEdit;
    lblPorta: TLabel;
    edtPorta: TEdit;
    lblBanco: TLabel;
    edtBanco: TEdit;
    lblUsuario: TLabel;
    edtUsuario: TEdit;
    lblSenha: TLabel;
    edtSenha: TEdit;
    lblCharset: TLabel;
    cbxCharset: TComboBox;
    lblDialeto: TLabel;
    cbxDialeto: TComboBox;
    procedure btnGravarClick(Sender: TObject);
    procedure btnTestarClick(Sender: TObject);
  private
    FDm: TdmConexoes;
    FDados: TConexaoDados;
    procedure CarregarTela;
    function LerTela: TConexaoDados;
  public
    class function Editar(ADm: TdmConexoes; var ADados: TConexaoDados): Boolean;
  end;

implementation

{$R *.dfm}

uses
  uMensagens;

class function TfrmConexaoEdicao.Editar(ADm: TdmConexoes; var ADados: TConexaoDados): Boolean;
var
  vForm: TfrmConexaoEdicao;
begin
  vForm := TfrmConexaoEdicao.Create(nil);
  try
    vForm.FDm := ADm;
    vForm.FDados := ADados;
    vForm.CarregarTela;
    Result := vForm.ShowModal = mrOk;
    if Result then
      ADados := vForm.FDados;
  finally
    vForm.Free;
  end;
end;

procedure TfrmConexaoEdicao.CarregarTela;
begin
  if FDados.Id = 0 then
    Caption := 'Nova conexão'
  else
    Caption := 'Editar conexão';

  edtNome.Text := FDados.Nome;
  cbxErp.ItemIndex := cbxErp.Items.IndexOf(FDados.Erp);
  edtServidor.Text := FDados.Servidor;
  edtPorta.Text := IntToStr(FDados.Porta);
  edtBanco.Text := FDados.Banco;
  edtUsuario.Text := FDados.Usuario;
  edtSenha.Text := FDados.Senha;
  cbxCharset.Text := FDados.Charset;
  cbxDialeto.ItemIndex := cbxDialeto.Items.IndexOf(IntToStr(FDados.Dialeto));
end;

function TfrmConexaoEdicao.LerTela: TConexaoDados;
begin
  Result := FDados;
  Result.Nome := Trim(edtNome.Text);
  Result.Erp := cbxErp.Text;
  Result.Servidor := Trim(edtServidor.Text);
  Result.Porta := StrToIntDef(Trim(edtPorta.Text), 0);
  Result.Banco := Trim(edtBanco.Text);
  Result.Usuario := Trim(edtUsuario.Text);
  Result.Senha := edtSenha.Text;
  Result.Charset := Trim(cbxCharset.Text);
  Result.Dialeto := StrToIntDef(cbxDialeto.Text, 0);
end;

procedure TfrmConexaoEdicao.btnTestarClick(Sender: TObject);
begin
  Screen.Cursor := crHourGlass;
  try
    try
      TestarConexao(LerTela);
    except
      on E: Exception do
      begin
        Screen.Cursor := crDefault;
        TMensagens.Alerta('Falha ao conectar:' + sLineBreak + sLineBreak + E.Message);
        Exit;
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;

  TMensagens.Info('Conexão realizada com sucesso.');
end;

procedure TfrmConexaoEdicao.btnGravarClick(Sender: TObject);
var
  vDados: TConexaoDados;
begin
  vDados := LerTela;
  try
    FDm.Gravar(vDados);
  except
    on E: Exception do
    begin
      TMensagens.Alerta(E.Message);
      Exit;
    end;
  end;

  FDados := vDados;
  ModalResult := mrOk;
end;

end.
