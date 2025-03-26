// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator_ingredient.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalculatorIngredientAdapter extends TypeAdapter<CalculatorIngredient> {
  @override
  final int typeId = 3;

  @override
  CalculatorIngredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalculatorIngredient(
      id: fields[0] as String,
      name: fields[1] as String,
      quantity: fields[2] as double,
      unit: fields[3] as String,
      price: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CalculatorIngredient obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.price);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculatorIngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
