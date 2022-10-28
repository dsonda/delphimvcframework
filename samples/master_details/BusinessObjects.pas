unit BusinessObjects;

// *************************************************************************** }
//
// Delphi MVC Framework
//
// Copyright (c) 2010-2022 Daniele Teti and the DMVCFramework Team
//
// https://github.com/danieleteti/delphimvcframework
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

interface

uses
  MVCFramework.Serializer.Commons,
  MVCFramework.ActiveRecord,
  MVCFramework.Nullables,
  MVCFramework.Rtti.Utils,
  System.Generics.Collections,
  System.Classes;

type

  [MVCNameCase(ncCamelCase)]
  [MVCTable('articles')]
  TArticles = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: Int64;
    [MVCTableField('description')]
    fDescription: String;
    [MVCTableField('price')]
    fPrice: Integer;
  public
    constructor Create; override;
    destructor Destroy; override;
    property ID: Int64 read fID write fID;
    property Description: String read fDescription write fDescription;
    property Price: Integer read fPrice write fPrice;
  end;

  [MVCNameCase(ncCamelCase)]
  [MVCTable('order_details')]
  TOrderDetail = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: NullableInt64;
    [MVCTableField('id_order')]
    fIDOrder: Int64;
    [MVCTableField('id_article')]
    fIDArticle: Int64;
    [MVCTableField('unit_price')]
    fUnitPrice: Currency;
    [MVCTableField('discount')]
    fDiscount: Integer;
    [MVCTableField('quantity')]
    fQuantity: Integer;
    [MVCTableField('description')]
    fDescription: String;
    [MVCTableField('total')]
    fTotal: Currency;
    procedure SetDescription(const Value: String);
    procedure SetDiscount(const Value: Integer);
    procedure SetQuantity(const Value: Integer);
    procedure SetUnitPrice(const Value: Currency);
  protected
    procedure OnBeforeInsertOrUpdate; override;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure RecalcTotal;
    function Clone: TOrderDetail;
    procedure Assign(Value: TMVCActiveRecord); override;
    property ID: NullableInt64 read fID write fID;
    [MVCDoNotSerialize]
    property IDOrder: Int64 read fIDOrder write fIDOrder;
    property IDArticle: Int64 read fIDArticle write fIDArticle;
    property UnitPrice: Currency read fUnitPrice write SetUnitPrice;
    property Discount: Integer read fDiscount write SetDiscount;
    property Quantity: Integer read fQuantity write SetQuantity;
    property Description: String read fDescription write SetDescription;
    property Total: Currency read fTotal;
  end;

  [MVCNameCase(ncCamelCase)]
  [MVCTable('orders')]
  TOrder = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    fID: NullableUInt64;
    [MVCTableField('id_customer')]
    fIDCustomer: Integer;
    [MVCTableField('order_date')]
    fOrderDate: TDate;
    [MVCTableField('total')]
    fTotal: Currency;
    [MVCOwned]
    fDetails: TObjectList<TOrderDetail>;
  protected
    procedure OnAfterLoad; override;
    procedure OnAfterInsertOrUpdate; override;
    procedure OnBeforeInsertOrUpdate; override;
    procedure RecalcTotals;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure AddOrderItem(const OrderItem: TOrderDetail);
    procedure UpdateOrderItemByID(const OrderItemID: Integer; const OrderItem: TOrderDetail);
    function GetOrderDetailByID(const Value: Int64): TOrderDetail;
    property ID: NullableUInt64 read fID write fID;
    [MVCNameAs('idCustomer')]
    property IDCustomer: Integer read fIDCustomer write fIDCustomer;
    property OrderDate: TDate read fOrderDate write fOrderDate;
    property Total: Currency read fTotal write fTotal;
    property OrderItems: TObjectList<TOrderDetail> read fDetails;
  end;

  [MVCNameCase(ncCamelCase)]
  TOrderIn = class
  private
    fID: NullableUInt64;
    fIDCustomer: NullableUInt64;
    fOrderDate: NullableTDate;
    fTotal: NullableCurrency;
    [MVCOwned(TOrderDetail)]
    fDetails: TObjectList<TOrderDetail>;
  public
    constructor Create;
    destructor Destroy; override;
    property ID: NullableUInt64 read fID write fID;
    [MVCNameAs('idCustomer')]
    property IDCustomer: NullableUInt64 read fIDCustomer write fIDCustomer;
    property OrderDate: NullableTDate read fOrderDate write fOrderDate;
    property Total: NullableCurrency read fTotal write fTotal;
    property OrderItems: TObjectList<TOrderDetail> read fDetails;
  end;

implementation

uses
  System.SysUtils;

constructor TArticles.Create;
begin
  inherited Create;
end;

destructor TArticles.Destroy;
begin
  inherited;
end;

procedure TOrderDetail.Assign(Value: TMVCActiveRecord);
var
  lObj: TOrderDetail;
begin
  if Value is TOrderDetail then
  begin
    lObj := TOrderDetail(Value);
    self.ID := lObj.ID;
    self.IDOrder := lObj.IDOrder;
    self.IDArticle := lObj.IDArticle;
    self.UnitPrice := lObj.UnitPrice;
    self.Discount := lObj.Discount;
    self.Quantity := lObj.Quantity;
    self.Description := lObj.Description;
  end
  else
  begin
    inherited;
  end;
end;

function TOrderDetail.Clone: TOrderDetail;
begin
  Result := TOrderDetail.Create;
  Result.Assign(Self);
end;

constructor TOrderDetail.Create;
begin
  inherited Create;
end;

destructor TOrderDetail.Destroy;
begin
  inherited;
end;

procedure TOrderDetail.OnBeforeInsertOrUpdate;
begin
  inherited;
  RecalcTotal;
end;

procedure TOrderDetail.RecalcTotal;
begin
  fTotal := fUnitPrice * fQuantity * (1 - fDiscount / 100);
end;

procedure TOrderDetail.SetDescription(const Value: String);
begin
  fDescription := Value;
end;

procedure TOrderDetail.SetDiscount(const Value: Integer);
begin
  fDiscount := Value;
  RecalcTotal;
end;

procedure TOrderDetail.SetQuantity(const Value: Integer);
begin
  fQuantity := Value;
  RecalcTotal;
end;

procedure TOrderDetail.SetUnitPrice(const Value: Currency);
begin
  fUnitPrice := Value;
  RecalcTotal;
end;

procedure TOrder.AddOrderItem(const OrderItem: TOrderDetail);
begin
  OrderItem.IDOrder := ID;
  OrderItems.Add(OrderItem);
end;

constructor TOrder.Create;
begin
  inherited Create;
  fDetails := TObjectList<TOrderDetail>.Create(true);
end;

destructor TOrder.Destroy;
begin
  fDetails.Free;
  inherited;
end;

function TOrder.GetOrderDetailByID(const Value: Int64): TOrderDetail;
var
  lOrderDetail: TOrderDetail;
begin
  inherited;
  for lOrderDetail in fDetails do
  begin
    if lOrderDetail.ID.Value = Value then
    begin
      Exit(lOrderDetail);
    end;
  end;
  raise EMVCActiveRecord.Create('Item not found');
end;

procedure TOrder.OnAfterInsertOrUpdate;
begin
  inherited;
  for var lOrderItem in OrderItems do
  begin
    lOrderItem.IDOrder := ID;
    lOrderItem.Store;
  end;
end;

procedure TOrder.OnBeforeInsertOrUpdate;
begin
  inherited;
  RecalcTotals;
end;

procedure TOrder.RecalcTotals;
begin
  fTotal := 0;
  for var lOrderItem in fDetails do
  begin
    fTotal := fTotal + lOrderItem.Total;
  end;
end;

procedure TOrder.UpdateOrderItemByID(const OrderItemID: Integer;
  const OrderItem: TOrderDetail);
begin
  var lObj := GetOrderDetailByID(OrderItemID);
  lObj.Assign(OrderItem);
  lObj.IDOrder := ID;
end;

procedure TOrder.OnAfterLoad;
var
  lList: TObjectList<TOrderDetail>;
begin
  inherited;
  lList := TMVCActiveRecord.SelectRQL<TOrderDetail>(Format('eq(idOrder,%d)',[ID.Value]), 1000);
  try
    fDetails.Clear;
    fDetails.AddRange(lList);
    lList.OwnsObjects := False;
  finally
    lList.Free;
  end;
end;


{ TOrderIn }

constructor TOrderIn.Create;
begin
  inherited;
  fDetails := TObjectList<TOrderDetail>.Create(true);
end;

destructor TOrderIn.Destroy;
begin
  fDetails.Free;
  inherited;
end;

end.
