// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_pay_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BillingPayEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingPayEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BillingPayEvent()';
}


}

/// @nodoc
class $BillingPayEventCopyWith<$Res>  {
$BillingPayEventCopyWith(BillingPayEvent _, $Res Function(BillingPayEvent) __);
}


/// Adds pattern-matching-related methods to [BillingPayEvent].
extension BillingPayEventPatterns on BillingPayEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Charge value)?  charge,TResult Function( _Poll value)?  poll,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Charge() when charge != null:
return charge(_that);case _Poll() when poll != null:
return poll(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Charge value)  charge,required TResult Function( _Poll value)  poll,}){
final _that = this;
switch (_that) {
case _Charge():
return charge(_that);case _Poll():
return poll(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Charge value)?  charge,TResult? Function( _Poll value)?  poll,}){
final _that = this;
switch (_that) {
case _Charge() when charge != null:
return charge(_that);case _Poll() when poll != null:
return poll(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String method)?  charge,TResult Function()?  poll,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Charge() when charge != null:
return charge(_that.method);case _Poll() when poll != null:
return poll();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String method)  charge,required TResult Function()  poll,}) {final _that = this;
switch (_that) {
case _Charge():
return charge(_that.method);case _Poll():
return poll();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String method)?  charge,TResult? Function()?  poll,}) {final _that = this;
switch (_that) {
case _Charge() when charge != null:
return charge(_that.method);case _Poll() when poll != null:
return poll();case _:
  return null;

}
}

}

/// @nodoc


class _Charge implements BillingPayEvent {
  const _Charge(this.method);
  

 final  String method;

/// Create a copy of BillingPayEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChargeCopyWith<_Charge> get copyWith => __$ChargeCopyWithImpl<_Charge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Charge&&(identical(other.method, method) || other.method == method));
}


@override
int get hashCode => Object.hash(runtimeType,method);

@override
String toString() {
  return 'BillingPayEvent.charge(method: $method)';
}


}

/// @nodoc
abstract mixin class _$ChargeCopyWith<$Res> implements $BillingPayEventCopyWith<$Res> {
  factory _$ChargeCopyWith(_Charge value, $Res Function(_Charge) _then) = __$ChargeCopyWithImpl;
@useResult
$Res call({
 String method
});




}
/// @nodoc
class __$ChargeCopyWithImpl<$Res>
    implements _$ChargeCopyWith<$Res> {
  __$ChargeCopyWithImpl(this._self, this._then);

  final _Charge _self;
  final $Res Function(_Charge) _then;

/// Create a copy of BillingPayEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? method = null,}) {
  return _then(_Charge(
null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _Poll implements BillingPayEvent {
  const _Poll();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Poll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'BillingPayEvent.poll()';
}


}




/// @nodoc
mixin _$BillingPayState {

 BillingPayData get data;
/// Create a copy of BillingPayState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingPayStateCopyWith<BillingPayState> get copyWith => _$BillingPayStateCopyWithImpl<BillingPayState>(this as BillingPayState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingPayState&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'BillingPayState(data: $data)';
}


}

/// @nodoc
abstract mixin class $BillingPayStateCopyWith<$Res>  {
  factory $BillingPayStateCopyWith(BillingPayState value, $Res Function(BillingPayState) _then) = _$BillingPayStateCopyWithImpl;
@useResult
$Res call({
 BillingPayData data
});




}
/// @nodoc
class _$BillingPayStateCopyWithImpl<$Res>
    implements $BillingPayStateCopyWith<$Res> {
  _$BillingPayStateCopyWithImpl(this._self, this._then);

  final BillingPayState _self;
  final $Res Function(BillingPayState) _then;

/// Create a copy of BillingPayState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BillingPayData,
  ));
}

}


/// Adds pattern-matching-related methods to [BillingPayState].
extension BillingPayStatePatterns on BillingPayState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Ready value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ready() when ready != null:
return ready(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Ready value)  ready,}){
final _that = this;
switch (_that) {
case _Ready():
return ready(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Ready value)?  ready,}){
final _that = this;
switch (_that) {
case _Ready() when ready != null:
return ready(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BillingPayData data)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ready() when ready != null:
return ready(_that.data);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BillingPayData data)  ready,}) {final _that = this;
switch (_that) {
case _Ready():
return ready(_that.data);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BillingPayData data)?  ready,}) {final _that = this;
switch (_that) {
case _Ready() when ready != null:
return ready(_that.data);case _:
  return null;

}
}

}

/// @nodoc


class _Ready implements BillingPayState {
  const _Ready(this.data);
  

@override final  BillingPayData data;

/// Create a copy of BillingPayState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadyCopyWith<_Ready> get copyWith => __$ReadyCopyWithImpl<_Ready>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ready&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'BillingPayState.ready(data: $data)';
}


}

/// @nodoc
abstract mixin class _$ReadyCopyWith<$Res> implements $BillingPayStateCopyWith<$Res> {
  factory _$ReadyCopyWith(_Ready value, $Res Function(_Ready) _then) = __$ReadyCopyWithImpl;
@override @useResult
$Res call({
 BillingPayData data
});




}
/// @nodoc
class __$ReadyCopyWithImpl<$Res>
    implements _$ReadyCopyWith<$Res> {
  __$ReadyCopyWithImpl(this._self, this._then);

  final _Ready _self;
  final $Res Function(_Ready) _then;

/// Create a copy of BillingPayState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_Ready(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as BillingPayData,
  ));
}


}

// dart format on
