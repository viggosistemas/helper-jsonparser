unit JSONParser.Config;

interface

uses
  System.SysUtils;

type
  TCaseDefinition = (cdNone, cdLower, cdUpper, cdLowerCamelCase);

  TJSONParserConfig = class
  private
    class var FInstance: TJSONParserConfig;

    FCaseDefinition: TCaseDefinition;

    constructor createPrivate;
  public
    constructor Create;
    destructor Destroy; override;

    function CaseDefinition(Value: TCaseDefinition): TJSONParserConfig; overload;
    function CaseDefinition: TCaseDefinition; overload;

    class function GetInstance: TJSONParserConfig;
    class destructor UnInitialize;
  end;

implementation

{ TJSONParserConfig }

function TJSONParserConfig.CaseDefinition(Value: TCaseDefinition): TJSONParserConfig;
begin
  result := Self;
  FCaseDefinition := Value;
end;

function TJSONParserConfig.CaseDefinition: TCaseDefinition;
begin
  result := FCaseDefinition;
end;

constructor TJSONParserConfig.Create;
begin
  raise Exception.Create('Invoke the GetInstance Method.');
end;

constructor TJSONParserConfig.createPrivate;
begin

end;

destructor TJSONParserConfig.Destroy;
begin

  inherited;
end;

class function TJSONParserConfig.GetInstance: TJSONParserConfig;
begin
  if not Assigned(FInstance) then
  begin
    FInstance := TJSONParserConfig.createPrivate;
    FInstance.CaseDefinition(cdNone);
  end;
  Result := FInstance;
end;

class destructor TJSONParserConfig.UnInitialize;
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);
end;

end.
