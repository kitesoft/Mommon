// This is part of the Mommon Library
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
// This software is distributed without any warranty.
//
// @author Domenico Mammola (mimmo71@gmail.com - www.mammola.net)
unit mProgressClasses;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Classes, contnrs, math, sysutils,
  mProgress, mUtility;

type

  TmAbstractProgress = class;

  { TmThreadWithProgress }

  TmThreadWithProgress = class (TThread)
  protected
    FProgress : TmAbstractProgress;
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;

    procedure RefreshProgress;
    procedure RemoveProgress;
  end;

  TmProgressNotifyEvent = procedure (aSender : TmAbstractProgress) of object;

  { TmAbstractProgress }

  TmAbstractProgress = class (ImProgress)
  strict private
    FCaption : String;
  private
    FOnRefresh : TmProgressNotifyEvent;
    FOnRemove : TmProgressNotifyEvent;
    FOwnerThread : TmThreadWithProgress;
    FId : String;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Notify(const aMessage: string);

    property OwnerThread : TmThreadWithProgress read FOwnerThread write FOwnerThread;
    property OnRefresh : TmProgressNotifyEvent read FOnRefresh write FOnRefresh;
    property OnRemove : TmProgressNotifyEvent read FOnRemove write FOnRemove;
    property Caption : String read FCaption;
    property Id : String read FId;
  end;

  TmProgressGUI = class;

  TmProgressGUIClass = class of TmProgressGUI;

  TmProgressGUI = class abstract
  public
    constructor Create; virtual; abstract;
    procedure AddProgress(aProgress : TmAbstractProgress); virtual; abstract;
  end;


  { TmProgressGUIFactory }

  TmProgressGUIFactory = class
  strict private
    FCurrentProgressGUI : TmProgressGUI;
    FProgressGUIClass : TmProgressGUIClass;
    FFakeProgressGUI : TmProgressGUI;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterProgressGUIClass (aClass : TmProgressGUIClass);
    function GetCurrentProgressGUI : TmProgressGUI;
  end;

  function GetProgressGUIFactory : TmProgressGUIFactory;

implementation

type

  { TFakeProgressGUI }

  TFakeProgressGUI = class(TmProgressGUI)
  public
    constructor Create; override;
    procedure AddProgress(aProgress : TmAbstractProgress); override;
  end;

var
  internalProgressGUIFactory : TmProgressGUIFactory;

function GetProgressGUIFactory: TmProgressGUIFactory;
begin
  if not Assigned(internalProgressGUIFactory) then
    internalProgressGUIFactory:= TmProgressGUIFactory.Create;
  Result := internalProgressGUIFactory;
end;

{ TmThreadWithProgress }

destructor TmThreadWithProgress.Destroy;
begin
  FProgress.Free;
  inherited Destroy;
end;

procedure TmThreadWithProgress.AfterConstruction;
begin
  inherited AfterConstruction;
  FProgress := TmAbstractProgress.Create;
  FProgress.OwnerThread := Self;
end;

procedure TmThreadWithProgress.RefreshProgress;
begin
  FProgress.OnRefresh(FProgress);
end;

procedure TmThreadWithProgress.RemoveProgress;
begin
  FProgress.OnRemove(FProgress);
end;

{ TFakeProgressGUI }

constructor TFakeProgressGUI.Create;
begin
  //
end;

procedure TFakeProgressGUI.AddProgress(aProgress: TmAbstractProgress);
begin
  // do nothing
end;

{ TmProgressGUIFactory }

constructor TmProgressGUIFactory.Create;
begin
  FCurrentProgressGUI := nil;
  FProgressGUIClass:= nil;
  FFakeProgressGUI := TFakeProgressGUI.Create;
end;

destructor TmProgressGUIFactory.Destroy;
begin
  FreeAndNil(FFakeProgressGUI);
  FreeAndNil(FCurrentProgressGUI);
  inherited Destroy;
end;

procedure TmProgressGUIFactory.RegisterProgressGUIClass(aClass: TmProgressGUIClass);
begin
  FProgressGUIClass:= aClass;
end;

function TmProgressGUIFactory.GetCurrentProgressGUI: TmProgressGUI;
begin
  if FProgressGUIClass = nil then
    Result := FFakeProgressGUI
  else
  begin
    if not Assigned(FCurrentProgressGUI) then
      FCurrentProgressGUI := FProgressGUIClass.Create;
    Result := FCurrentProgressGUI;
  end;
end;

{ TmAbstractProgress }

procedure TmAbstractProgress.Notify(const aMessage: string);
begin
  if FCaption=aMessage then Exit;
  FCaption:=aMessage;
  FOwnerThread.Synchronize(FOwnerThread, FOwnerThread.RefreshProgress);
end;

constructor TmAbstractProgress.Create;
begin
  FCaption := '';
  FId := GenerateRandomIdString(30);
  GetProgressGUIFactory.GetCurrentProgressGUI.AddProgress(Self);
end;

destructor TmAbstractProgress.Destroy;
begin
  FOwnerThread.Synchronize(FOwnerThread, FOwnerThread.RemoveProgress);
  inherited Destroy;
end;


finalization
  FreeAndNil(internalProgressGUIFactory);

end.
