unit uCriptografia;

{ Criptografia de senhas com a DPAPI do Windows (CryptProtectData), escopo da máquina:
  qualquer usuário desta máquina descriptografa, mas o valor não serve em outra máquina. }

interface

uses
  Winapi.Windows, System.SysUtils, System.NetEncoding;

type
  TCriptografia = class
  public
    class function Criptografar(const ATexto: string): string; static;
    class function Descriptografar(const ATextoCriptografado: string): string; static;
  end;

implementation

type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

const
  CRYPTPROTECT_UI_FORBIDDEN = $1;
  CRYPTPROTECT_LOCAL_MACHINE = $4;
  // Não mudar (nem com a troca do nome do projeto): as senhas já gravadas só descriptografam com este valor
  cENTROPIA = 'BlessDataImport';

function CryptProtectData(pDataIn: PDataBlob; szDataDescr: PWideChar; pOptionalEntropy: PDataBlob;
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptProtectData';

function CryptUnprotectData(pDataIn: PDataBlob; ppszDataDescr: PPWideChar; pOptionalEntropy: PDataBlob;
  pvReserved: Pointer; pPromptStruct: Pointer; dwFlags: DWORD; pDataOut: PDataBlob): BOOL; stdcall;
  external 'crypt32.dll' name 'CryptUnprotectData';

function NovoBlob(const ABytes: TBytes): TDataBlob;
begin
  Result.cbData := Length(ABytes);
  if Result.cbData > 0 then
    Result.pbData := @ABytes[0]
  else
    Result.pbData := nil;
end;

function BlobParaBytes(const ABlob: TDataBlob): TBytes;
begin
  SetLength(Result, ABlob.cbData);
  if ABlob.cbData > 0 then
    Move(ABlob.pbData^, Result[0], ABlob.cbData);
end;

function NovoBase64: TBase64Encoding;
begin
  // CharsPerLine = 0: sem quebras de linha no texto gerado
  Result := TBase64Encoding.Create(0);
end;

class function TCriptografia.Criptografar(const ATexto: string): string;
var
  vTexto, vEntropia: TBytes;
  vEntrada, vBlobEntropia, vSaida: TDataBlob;
  vBase64: TBase64Encoding;
begin
  if ATexto = '' then
    Exit('');

  vTexto := TEncoding.UTF8.GetBytes(ATexto);
  vEntropia := TEncoding.UTF8.GetBytes(cENTROPIA);
  vEntrada := NovoBlob(vTexto);
  vBlobEntropia := NovoBlob(vEntropia);
  vSaida := Default(TDataBlob);

  if not CryptProtectData(@vEntrada, nil, @vBlobEntropia, nil, nil,
    CRYPTPROTECT_UI_FORBIDDEN or CRYPTPROTECT_LOCAL_MACHINE, @vSaida) then
    RaiseLastOSError;
  try
    vBase64 := NovoBase64;
    try
      Result := vBase64.EncodeBytesToString(BlobParaBytes(vSaida));
    finally
      vBase64.Free;
    end;
  finally
    LocalFree(HLOCAL(vSaida.pbData));
  end;
end;

class function TCriptografia.Descriptografar(const ATextoCriptografado: string): string;
var
  vDados, vEntropia: TBytes;
  vEntrada, vBlobEntropia, vSaida: TDataBlob;
  vBase64: TBase64Encoding;
begin
  if ATextoCriptografado = '' then
    Exit('');

  vBase64 := NovoBase64;
  try
    vDados := vBase64.DecodeStringToBytes(ATextoCriptografado);
  finally
    vBase64.Free;
  end;

  vEntropia := TEncoding.UTF8.GetBytes(cENTROPIA);
  vEntrada := NovoBlob(vDados);
  vBlobEntropia := NovoBlob(vEntropia);
  vSaida := Default(TDataBlob);

  if not CryptUnprotectData(@vEntrada, nil, @vBlobEntropia, nil, nil, CRYPTPROTECT_UI_FORBIDDEN, @vSaida) then
    raise Exception.Create('Não foi possível descriptografar a senha (ela foi gravada em outra máquina?). ' +
      'Informe a senha novamente.');
  try
    Result := TEncoding.UTF8.GetString(BlobParaBytes(vSaida));
  finally
    LocalFree(HLOCAL(vSaida.pbData));
  end;
end;

end.
