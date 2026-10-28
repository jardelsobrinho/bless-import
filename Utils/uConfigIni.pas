unit uConfigIni;

interface

uses
  System.IniFiles, System.SysUtils;

type
  TConfigIni = class
  public
    class function CaminhoArquivo: string; static;
    class function ArquivoExiste: Boolean; static;
    class procedure Gravar(const ASecao, AChave, AValor: string); static;
    class function Retornar(const ASecao, AChave, AValorPadrao: string): string; static;
  end;

implementation

class function TConfigIni.CaminhoArquivo: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'Config.ini';
end;

class function TConfigIni.ArquivoExiste: Boolean;
begin
  Result := FileExists(CaminhoArquivo);
end;

class procedure TConfigIni.Gravar(const ASecao, AChave, AValor: string);
var
  vIni: TIniFile;
begin
  vIni := TIniFile.Create(CaminhoArquivo);
  try
    vIni.WriteString(ASecao, AChave, AValor);
  finally
    vIni.Free;
  end;
end;

class function TConfigIni.Retornar(const ASecao, AChave, AValorPadrao: string): string;
var
  vIni: TIniFile;
begin
  vIni := TIniFile.Create(CaminhoArquivo);
  try
    Result := vIni.ReadString(ASecao, AChave, AValorPadrao);
  finally
    vIni.Free;
  end;
end;

end.
