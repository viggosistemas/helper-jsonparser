unit JSONParser.Helper;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.Generics.Collections,
  REST.Json,
  JSONParser.DateTime.Helper,
  JSONParser.Interfaces;

type
  TJSONParserObjectHelper = class helper for TJSONObject
  public
    {$IF CompilerVersion <= 32.0}
    function Format: string; overload;
    {$ENDIF}

    class function ObjectToJSONString(Value: TObject): string;
    class function ObjectToJSONStringWithBackslash(Value: TObject): string;

    class function fromObject(Value: TObject): TJSONObject;
    class function fromFile  (Value: String) : TJSONObject;
    class function fromString(Value: String) : TJSONObject;

    class function format(Value: string): string; overload;

    procedure SaveToFile(AFileName: String);
    procedure toObject(Value: TObject; bUseIgnore: boolean = True);

    function ValueAsString   (Name: string; Default: string = ''): string;
    function ValueAsInteger  (Name: string; Default: Integer = 0): Integer;
    function ValueAsFloat    (Name: string; Default: Double = 0): Double;
    function ValueAsDateTime (Name: string; AFormat: String = ''; Default: TDateTime = 0): TDateTime;
    function ValueAsBoolean  (Name: string; Default: Boolean = True): Boolean;

    function ValueAsJSONObject(Name: String): TJSONObject;
    function ValueAsJSONArray (Name: String): TJSONArray;

    function SetValue(Name: String; Value: Boolean): TJSONObject; overload;
    function SetValue(Name: String; Value: Integer): TJSONObject; overload;
    function SetValue(Name: String; Value: Double): TJSONObject; overload;
    function SetValue(Name, Value: String): TJSONObject; overload;

    function Encode: String;
  end;

  TJSONParserArrayHelper = class helper for TJSONArray
  private
    {$IF CompilerVersion <= 26.0}
    function GetItems(Index: Integer): TJSONValue;
    {$ENDIF}

    function GetFields: TList<String>;
  public
    {$IF CompilerVersion <= 26.0}
    function Count: Integer;
    property Items[Index: Integer]: TJSONValue read GetItems;
    {$ENDIF}

    function Encode: String;

    procedure ToCsvFile(AFileName: String; Separator: string); overload;
    class procedure ToCsvFile(JSONContent: String; AFileName: String; Separator: string); overload;
    function ToCsv(Separator: string = ';'): String; overload;
    class function ToCsv(JSONContent: String; Separator: string): String; overload;

    function ItemAsString(Index: Integer; Name: string; Default: string = ''): string;
    function ItemAsInteger(Index: Integer; Name: string; Default: Integer = 0): Integer;
    function ItemAsFloat  (Index: Integer; Name: string; Default: Double = 0): Double;
    function ItemAsDateTime(Index: Integer; Name: string; AFormat: String = ''; Default: TDateTime = 0): TDateTime;
    function ItemAsBoolean(Index: Integer; Name: string; Default: Boolean = True): Boolean;

    function ItemAsJSONObject(Index: Integer): TJSONObject; overload;
    function ItemAsJSONObject(Index: Integer; Name: String): TJSONObject; overload;
    function ItemAsJSONArray(Index: Integer): TJSONArray; overload;
    function ItemAsJSONArray(Index: Integer; Name: String): TJSONArray; overload;
    class function FromString(Value: String): TJSONArray;
  end;

  TObjectHelper = class helper for TObject
    public
      function ToJSONObject: TJSONObject;
      function ToJSONString(bFormat: Boolean = False; aBackslash: Boolean = False): string;
      procedure SaveToJSONFile(AFileName: String);

      procedure fromJSONObject(Value: TJSONObject);
      procedure fromJSONString(Value: String);
      procedure fromJSONFile(Value: String);
  end;

implementation

{ TJSONParserObjectHelper }

function TJSONParserObjectHelper.Encode: String;
begin
  {$IF CompilerVersion > 26}
  result := TJson.JsonEncode(Self);
  {$ELSE}
  result := Self.ToString;
  {$ENDIF}
end;

class function TJSONParserObjectHelper.format(Value: string): string;
var
  jsonObject: TJSONObject;
begin
  result     := EmptyStr;
  jsonObject := fromString(Value);
  try
    result := jsonObject.Format;
  finally
    jsonObject.Free;
  end;
end;

{$IF CompilerVersion <= 32.0}
function TJSONParserObjectHelper.Format: string;
begin
  Result := TJson.Format(Self);
end;
{$ENDIF}

class function TJSONParserObjectHelper.fromFile(Value: String): TJSONObject;
var
  fileJSON: TStringList;
begin
  if not FileExists(Value) then
    raise EFileNotFoundException.CreateFmt('File %s not found.', [Value]);

  fileJSON := TStringList.Create;
  try
    fileJSON.LoadFromFile(Value);
    result := fromString(fileJSON.Text);
  finally
    fileJSON.Free;
  end;
end;

class function TJSONParserObjectHelper.fromObject(Value: TObject): TJSONObject;
begin
  result := TJSONParserDefault.Deserializer.ObjectToJsonObject(Value);
end;

class function TJSONParserObjectHelper.fromString(Value: String): TJSONObject;
begin
  result := TJSONParserDefault.Deserializer.StringToJsonObject(Value);
end;

class function TJSONParserObjectHelper.ObjectToJSONString(Value: TObject): string;
begin
  result := TJSONParserDefault.Deserializer.ObjectToJsonString(Value);
end;

class function TJSONParserObjectHelper.ObjectToJSONStringWithBackslash(Value: TObject): string;
begin
  result := TJSONParserDefault.Deserializer(True, True).ObjectToJsonString(Value);
end;

procedure TJSONParserObjectHelper.SaveToFile(AFileName: String);
var
  fileJSON: TStringList;
begin
  fileJSON := TStringList.Create;
  try
    fileJSON.Text := Self.Format;
    fileJSON.SaveToFile(AFileName);
  finally
    fileJSON.Free;
  end;
end;

function TJSONParserObjectHelper.SetValue(Name: String; Value: Boolean): TJSONObject;
begin
  result := Self;
  if Value then
    Self.AddPair(Name, TJSONTrue.Create)
  else
    Self.AddPair(Name, TJSONFalse.Create)
end;

function TJSONParserObjectHelper.SetValue(Name: String; Value: Integer): TJSONObject;
begin
  result := Self;
  Self.AddPair(Name, TJSONNumber.Create(Value));
end;

function TJSONParserObjectHelper.SetValue(Name: String; Value: Double): TJSONObject;
begin
  result := Self;
  Self.AddPair(Name, TJSONNumber.Create(Value));
end;

function TJSONParserObjectHelper.SetValue(Name, Value: String): TJSONObject;
begin
  result := Self;
  Self.AddPair(Name, TJSONString.Create(Value));
end;

procedure TJSONParserObjectHelper.toObject(Value: TObject; bUseIgnore: boolean = True);
begin
  TJSONParserDefault.Serializer(bUseIgnore).JsonObjectToObject(Value, Self);
end;

function TJSONParserObjectHelper.ValueAsBoolean(Name: string; Default: Boolean): Boolean;
var
  strValue: string;
begin
  result := Default;
  if GetValue(Name) <> nil then
  begin
    strValue := GetValue(Name).ToString;
    result := not strValue.Equals('false');
  end;
end;

function TJSONParserObjectHelper.ValueAsDateTime(Name, AFormat: String; Default: TDateTime): TDateTime;
var
  strValue: string;
begin
  result := Default;
  strValue := ValueAsString(Name, '0');
  result.fromIso8601ToDateTime(strValue);
end;

function TJSONParserObjectHelper.ValueAsFloat(Name: string; Default: Double): Double;
var
  strValue: string;
begin
  strValue := ValueAsString(Name, Default.ToString);
  result := StrToFloatDef(strValue, Default);
end;

function TJSONParserObjectHelper.ValueAsInteger(Name: string; Default: Integer): Integer;
var
  strValue: string;
begin
  strValue := ValueAsString(Name, default.ToString);
  result := StrToIntDef(strValue, Default);
end;

function TJSONParserObjectHelper.ValueAsJSONArray(Name: String): TJSONArray;
begin
  result := nil;
  if GetValue(Name) is TJSONArray then
    result := TJSONArray( GetValue(Name) );
end;

function TJSONParserObjectHelper.ValueAsJSONObject(Name: String): TJSONObject;
begin
  result := nil;
  if GetValue(Name) is TJSONObject then
    result := TJSONObject( GetValue(Name) );
end;

function TJSONParserObjectHelper.ValueAsString(Name, Default: string): string;
begin
  result := Default;
  if GetValue(Name) <> nil then
    result := GetValue(Name).Value;
end;

{ TObjectHelper }

procedure TObjectHelper.fromJSONObject(Value: TJSONObject);
begin
  if Assigned(Value) then
    Value.toObject(Self);
end;

procedure TObjectHelper.fromJSONString(Value: String);
var
  json : TJSONObject;
begin
  json := TJSONObject.fromString(Value);
  try
    if Assigned(json) then
      fromJSONObject(json);
  finally
    json.Free;
  end;
end;

procedure TObjectHelper.fromJSONFile(Value: String);
var
  fileJSON: TStringList;
begin
  if not FileExists(Value) then
    raise EFileNotFoundException.CreateFmt('File %s not found.', [Value]);

  fileJSON := TStringList.Create;
  try
    fileJSON.LoadFromFile(Value);
    fromJSONString(fileJSON.Text);
  finally
    fileJSON.Free;
  end;

end;

procedure TObjectHelper.SaveToJSONFile(AFileName: String);
var
  json: TJSONObject;
begin
  json := Self.ToJSONObject;
  try
    json.SaveToFile(AFileName);
  finally
    json.Free;
  end;
end;

function TObjectHelper.ToJSONObject: TJSONObject;
begin
  result := TJSONObject.fromObject(Self);
end;

function TObjectHelper.ToJSONString(bFormat: Boolean = False; aBackslash: Boolean = False): string;
begin
  if aBackslash then
    result := TJSONObject.ObjectToJSONStringWithBackslash(Self)
  else
    result := TJSONObject.ObjectToJSONString(Self);

  if bFormat then
    result := TJSONObject.format(result);
end;

{ TJSONParserArrayHelper }

{$IF CompilerVersion <= 26.0}
function TJSONParserArrayHelper.Count: Integer;
begin
  result := Self.Size;
end;
{$ENDIF}

function TJSONParserArrayHelper.Encode: String;
begin
  {$IF CompilerVersion > 26}
  result := TJson.JsonEncode(Self);
  {$ELSE}
  result := Self.ToString;
  {$ENDIF}
end;

class function TJSONParserArrayHelper.FromString(Value: String): TJSONArray;
begin
  result := TJSONObject.ParseJSONValue(Value) as TJSONArray;
end;

function TJSONParserArrayHelper.GetFields: TList<String>;
var
  i, j: Integer;
  json: TJSONObject;
  name: String;
begin
  result := TList<String>.create;
  try
    for i := 0 to Pred(Self.Count) do
    begin
      json := Self.ItemAsJSONObject(i);
      for j := 0 to Pred(json.Count) do
      begin
        name := json.Pairs[j].JsonString.Value;
        if (not result.Contains(name)) and
           (not (json.GetValue(name) is TJSONObject)) and
           (not (json.GetValue(name) is TJSONArray))
        then
          result.Add(name);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

{$IF CompilerVersion <= 26.0}
function TADRIFoodHelperJSONArray.GetItems(Index: Integer): TJSONValue;
begin
  {$IF CompilerVersion > 26.0}
  result := Self.Items[Index];
  {$ELSE}
  result := Self.Get(Index);
  {$ENDIF}
end;
{$ENDIF}

function TJSONParserArrayHelper.ItemAsBoolean(Index: Integer; Name: string; Default: Boolean): Boolean;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsBoolean(Name, Default);
end;

function TJSONParserArrayHelper.ItemAsDateTime(Index: Integer; Name, AFormat: String; Default: TDateTime): TDateTime;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsDateTime(Name, AFormat, Default);
end;

function TJSONParserArrayHelper.ItemAsFloat(Index: Integer; Name: string; Default: Double): Double;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsFloat(Name, Default);
end;

function TJSONParserArrayHelper.ItemAsInteger(Index: Integer; Name: string; Default: Integer): Integer;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsInteger(Name, Default);
end;

function TJSONParserArrayHelper.ItemAsJSONArray(Index: Integer): TJSONArray;
begin
  result := {$IF CompilerVersion > 26.0} Items[Index] as TJSONArray; {$ELSE} Self.Get(Index) as TJSONArray; {$ENDIF}
end;

function TJSONParserArrayHelper.ItemAsJSONArray(Index: Integer; Name: String): TJSONArray;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsJSONArray(Name);
end;

function TJSONParserArrayHelper.ItemAsJSONObject(Index: Integer; Name: String): TJSONObject;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsJSONObject(Name);
end;

function TJSONParserArrayHelper.ItemAsJSONObject(Index: Integer): TJSONObject;
begin
  result := {$IF CompilerVersion > 26.0} Items[Index] as TJSONObject; {$ELSE} Self.Get(Index) as TJSONObject; {$ENDIF}
end;

function TJSONParserArrayHelper.ItemAsString(Index: Integer; Name, Default: string): string;
var
  json: TJSONObject;
begin
  json := ItemAsJSONObject(Index);
  result := json.ValueAsString(Name, Default);
end;

class function TJSONParserArrayHelper.ToCsv(JSONContent: String; Separator: string): String;
var
  jsonArray: TJSONArray;
begin
  jsonArray := Self.FromString(JSONContent);
  try
    result := jsonArray.ToCsv(Separator);
  finally
    jsonArray.Free;
  end;
end;

class procedure TJSONParserArrayHelper.ToCsvFile(JSONContent, AFileName: String; Separator: string);
var
  jsonArray: TJSONArray;
begin
  jsonArray := FromString(JSONContent);
  try
    jsonArray.ToCsvFile(AFileName, Separator);
  finally
    jsonArray.Free;
  end;
end;

procedure TJSONParserArrayHelper.ToCsvFile(AFileName: String; Separator: string);
begin
  with TStringList.Create do
  try
    Text := Self.ToCsv(Separator);
    SaveToFile(AFileName);
  finally
    Free;
  end;
end;

function TJSONParserArrayHelper.ToCsv(Separator: string = ';'): String;
var
  fields: TList<String>;
  csv: TStrings;
  line: string;
  i, j: Integer;
begin
  fields := GetFields;
  try
    csv := TStringList.Create;
    try
      for i := 0 to Pred(fields.Count) do
      begin
        if i = 0 then
          line := '"' + fields[i] + '"'
        else
          line := line + Separator + '"' + fields[i] + '"';
      end;

      csv.Add(line);
      for i := 0 to Pred(Self.Count) do
      begin
        line := EmptyStr;
        for j := 0 to Pred(fields.Count) do
        begin
          if j = 0 then
            line := '"' + Self.ItemAsString(i, fields[j]) + '"'
          else
            line := line + Separator + '"' + Self.ItemAsString(i, fields[j]) + '"';
        end;
        csv.Add(line);
      end;

      Result := csv.Text;
    finally
      csv.Free;
    end;
  finally
    fields.Free;
  end;
end;

end.
