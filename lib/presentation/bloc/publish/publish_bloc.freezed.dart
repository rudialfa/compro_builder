// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'publish_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PublishEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublishEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PublishEvent()';
}


}

/// @nodoc
class $PublishEventCopyWith<$Res>  {
$PublishEventCopyWith(PublishEvent _, $Res Function(PublishEvent) __);
}


/// Adds pattern-matching-related methods to [PublishEvent].
extension PublishEventPatterns on PublishEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SetStatus value)?  setStatus,TResult Function( _Dismissed value)?  dismissed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetStatus() when setStatus != null:
return setStatus(_that);case _Dismissed() when dismissed != null:
return dismissed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SetStatus value)  setStatus,required TResult Function( _Dismissed value)  dismissed,}){
final _that = this;
switch (_that) {
case _SetStatus():
return setStatus(_that);case _Dismissed():
return dismissed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SetStatus value)?  setStatus,TResult? Function( _Dismissed value)?  dismissed,}){
final _that = this;
switch (_that) {
case _SetStatus() when setStatus != null:
return setStatus(_that);case _Dismissed() when dismissed != null:
return dismissed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SiteStatus target)?  setStatus,TResult Function()?  dismissed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetStatus() when setStatus != null:
return setStatus(_that.target);case _Dismissed() when dismissed != null:
return dismissed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SiteStatus target)  setStatus,required TResult Function()  dismissed,}) {final _that = this;
switch (_that) {
case _SetStatus():
return setStatus(_that.target);case _Dismissed():
return dismissed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SiteStatus target)?  setStatus,TResult? Function()?  dismissed,}) {final _that = this;
switch (_that) {
case _SetStatus() when setStatus != null:
return setStatus(_that.target);case _Dismissed() when dismissed != null:
return dismissed();case _:
  return null;

}
}

}

/// @nodoc


class _SetStatus implements PublishEvent {
  const _SetStatus(this.target);
  

 final  SiteStatus target;

/// Create a copy of PublishEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetStatusCopyWith<_SetStatus> get copyWith => __$SetStatusCopyWithImpl<_SetStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetStatus&&(identical(other.target, target) || other.target == target));
}


@override
int get hashCode => Object.hash(runtimeType,target);

@override
String toString() {
  return 'PublishEvent.setStatus(target: $target)';
}


}

/// @nodoc
abstract mixin class _$SetStatusCopyWith<$Res> implements $PublishEventCopyWith<$Res> {
  factory _$SetStatusCopyWith(_SetStatus value, $Res Function(_SetStatus) _then) = __$SetStatusCopyWithImpl;
@useResult
$Res call({
 SiteStatus target
});




}
/// @nodoc
class __$SetStatusCopyWithImpl<$Res>
    implements _$SetStatusCopyWith<$Res> {
  __$SetStatusCopyWithImpl(this._self, this._then);

  final _SetStatus _self;
  final $Res Function(_SetStatus) _then;

/// Create a copy of PublishEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? target = null,}) {
  return _then(_SetStatus(
null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as SiteStatus,
  ));
}


}

/// @nodoc


class _Dismissed implements PublishEvent {
  const _Dismissed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Dismissed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PublishEvent.dismissed()';
}


}




// dart format on
