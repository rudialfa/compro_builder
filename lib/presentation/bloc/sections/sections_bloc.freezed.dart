// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sections_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SectionsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SectionsEvent()';
}


}

/// @nodoc
class $SectionsEventCopyWith<$Res>  {
$SectionsEventCopyWith(SectionsEvent _, $Res Function(SectionsEvent) __);
}


/// Adds pattern-matching-related methods to [SectionsEvent].
extension SectionsEventPatterns on SectionsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Fetch value)?  fetch,TResult Function( _Refresh value)?  refresh,TResult Function( _Toggle value)?  toggle,TResult Function( _Move value)?  move,TResult Function( _Delete value)?  delete,TResult Function( _Add value)?  add,TResult Function( _SectionReplaced value)?  sectionReplaced,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch(_that);case _Refresh() when refresh != null:
return refresh(_that);case _Toggle() when toggle != null:
return toggle(_that);case _Move() when move != null:
return move(_that);case _Delete() when delete != null:
return delete(_that);case _Add() when add != null:
return add(_that);case _SectionReplaced() when sectionReplaced != null:
return sectionReplaced(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Fetch value)  fetch,required TResult Function( _Refresh value)  refresh,required TResult Function( _Toggle value)  toggle,required TResult Function( _Move value)  move,required TResult Function( _Delete value)  delete,required TResult Function( _Add value)  add,required TResult Function( _SectionReplaced value)  sectionReplaced,}){
final _that = this;
switch (_that) {
case _Fetch():
return fetch(_that);case _Refresh():
return refresh(_that);case _Toggle():
return toggle(_that);case _Move():
return move(_that);case _Delete():
return delete(_that);case _Add():
return add(_that);case _SectionReplaced():
return sectionReplaced(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Fetch value)?  fetch,TResult? Function( _Refresh value)?  refresh,TResult? Function( _Toggle value)?  toggle,TResult? Function( _Move value)?  move,TResult? Function( _Delete value)?  delete,TResult? Function( _Add value)?  add,TResult? Function( _SectionReplaced value)?  sectionReplaced,}){
final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch(_that);case _Refresh() when refresh != null:
return refresh(_that);case _Toggle() when toggle != null:
return toggle(_that);case _Move() when move != null:
return move(_that);case _Delete() when delete != null:
return delete(_that);case _Add() when add != null:
return add(_that);case _SectionReplaced() when sectionReplaced != null:
return sectionReplaced(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetch,TResult Function()?  refresh,TResult Function( int id)?  toggle,TResult Function( int id,  bool up)?  move,TResult Function( int id)?  delete,TResult Function( SectionTypeModel type)?  add,TResult Function( SectionModel section)?  sectionReplaced,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch();case _Refresh() when refresh != null:
return refresh();case _Toggle() when toggle != null:
return toggle(_that.id);case _Move() when move != null:
return move(_that.id,_that.up);case _Delete() when delete != null:
return delete(_that.id);case _Add() when add != null:
return add(_that.type);case _SectionReplaced() when sectionReplaced != null:
return sectionReplaced(_that.section);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetch,required TResult Function()  refresh,required TResult Function( int id)  toggle,required TResult Function( int id,  bool up)  move,required TResult Function( int id)  delete,required TResult Function( SectionTypeModel type)  add,required TResult Function( SectionModel section)  sectionReplaced,}) {final _that = this;
switch (_that) {
case _Fetch():
return fetch();case _Refresh():
return refresh();case _Toggle():
return toggle(_that.id);case _Move():
return move(_that.id,_that.up);case _Delete():
return delete(_that.id);case _Add():
return add(_that.type);case _SectionReplaced():
return sectionReplaced(_that.section);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetch,TResult? Function()?  refresh,TResult? Function( int id)?  toggle,TResult? Function( int id,  bool up)?  move,TResult? Function( int id)?  delete,TResult? Function( SectionTypeModel type)?  add,TResult? Function( SectionModel section)?  sectionReplaced,}) {final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch();case _Refresh() when refresh != null:
return refresh();case _Toggle() when toggle != null:
return toggle(_that.id);case _Move() when move != null:
return move(_that.id,_that.up);case _Delete() when delete != null:
return delete(_that.id);case _Add() when add != null:
return add(_that.type);case _SectionReplaced() when sectionReplaced != null:
return sectionReplaced(_that.section);case _:
  return null;

}
}

}

/// @nodoc


class _Fetch implements SectionsEvent {
  const _Fetch();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fetch);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SectionsEvent.fetch()';
}


}




/// @nodoc


class _Refresh implements SectionsEvent {
  const _Refresh();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Refresh);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SectionsEvent.refresh()';
}


}




/// @nodoc


class _Toggle implements SectionsEvent {
  const _Toggle(this.id);
  

 final  int id;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToggleCopyWith<_Toggle> get copyWith => __$ToggleCopyWithImpl<_Toggle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Toggle&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'SectionsEvent.toggle(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ToggleCopyWith<$Res> implements $SectionsEventCopyWith<$Res> {
  factory _$ToggleCopyWith(_Toggle value, $Res Function(_Toggle) _then) = __$ToggleCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class __$ToggleCopyWithImpl<$Res>
    implements _$ToggleCopyWith<$Res> {
  __$ToggleCopyWithImpl(this._self, this._then);

  final _Toggle _self;
  final $Res Function(_Toggle) _then;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_Toggle(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Move implements SectionsEvent {
  const _Move(this.id, {required this.up});
  

 final  int id;
 final  bool up;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoveCopyWith<_Move> get copyWith => __$MoveCopyWithImpl<_Move>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Move&&(identical(other.id, id) || other.id == id)&&(identical(other.up, up) || other.up == up));
}


@override
int get hashCode => Object.hash(runtimeType,id,up);

@override
String toString() {
  return 'SectionsEvent.move(id: $id, up: $up)';
}


}

/// @nodoc
abstract mixin class _$MoveCopyWith<$Res> implements $SectionsEventCopyWith<$Res> {
  factory _$MoveCopyWith(_Move value, $Res Function(_Move) _then) = __$MoveCopyWithImpl;
@useResult
$Res call({
 int id, bool up
});




}
/// @nodoc
class __$MoveCopyWithImpl<$Res>
    implements _$MoveCopyWith<$Res> {
  __$MoveCopyWithImpl(this._self, this._then);

  final _Move _self;
  final $Res Function(_Move) _then;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? up = null,}) {
  return _then(_Move(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,up: null == up ? _self.up : up // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _Delete implements SectionsEvent {
  const _Delete(this.id);
  

 final  int id;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteCopyWith<_Delete> get copyWith => __$DeleteCopyWithImpl<_Delete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Delete&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'SectionsEvent.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class _$DeleteCopyWith<$Res> implements $SectionsEventCopyWith<$Res> {
  factory _$DeleteCopyWith(_Delete value, $Res Function(_Delete) _then) = __$DeleteCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class __$DeleteCopyWithImpl<$Res>
    implements _$DeleteCopyWith<$Res> {
  __$DeleteCopyWithImpl(this._self, this._then);

  final _Delete _self;
  final $Res Function(_Delete) _then;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_Delete(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _Add implements SectionsEvent {
  const _Add(this.type);
  

 final  SectionTypeModel type;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddCopyWith<_Add> get copyWith => __$AddCopyWithImpl<_Add>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Add&&(identical(other.type, type) || other.type == type));
}


@override
int get hashCode => Object.hash(runtimeType,type);

@override
String toString() {
  return 'SectionsEvent.add(type: $type)';
}


}

/// @nodoc
abstract mixin class _$AddCopyWith<$Res> implements $SectionsEventCopyWith<$Res> {
  factory _$AddCopyWith(_Add value, $Res Function(_Add) _then) = __$AddCopyWithImpl;
@useResult
$Res call({
 SectionTypeModel type
});




}
/// @nodoc
class __$AddCopyWithImpl<$Res>
    implements _$AddCopyWith<$Res> {
  __$AddCopyWithImpl(this._self, this._then);

  final _Add _self;
  final $Res Function(_Add) _then;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? type = null,}) {
  return _then(_Add(
null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SectionTypeModel,
  ));
}


}

/// @nodoc


class _SectionReplaced implements SectionsEvent {
  const _SectionReplaced(this.section);
  

 final  SectionModel section;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectionReplacedCopyWith<_SectionReplaced> get copyWith => __$SectionReplacedCopyWithImpl<_SectionReplaced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SectionReplaced&&(identical(other.section, section) || other.section == section));
}


@override
int get hashCode => Object.hash(runtimeType,section);

@override
String toString() {
  return 'SectionsEvent.sectionReplaced(section: $section)';
}


}

/// @nodoc
abstract mixin class _$SectionReplacedCopyWith<$Res> implements $SectionsEventCopyWith<$Res> {
  factory _$SectionReplacedCopyWith(_SectionReplaced value, $Res Function(_SectionReplaced) _then) = __$SectionReplacedCopyWithImpl;
@useResult
$Res call({
 SectionModel section
});




}
/// @nodoc
class __$SectionReplacedCopyWithImpl<$Res>
    implements _$SectionReplacedCopyWith<$Res> {
  __$SectionReplacedCopyWithImpl(this._self, this._then);

  final _SectionReplaced _self;
  final $Res Function(_SectionReplaced) _then;

/// Create a copy of SectionsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? section = null,}) {
  return _then(_SectionReplaced(
null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as SectionModel,
  ));
}


}

/// @nodoc
mixin _$SectionsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SectionsState()';
}


}

/// @nodoc
class $SectionsStateCopyWith<$Res>  {
$SectionsStateCopyWith(SectionsState _, $Res Function(SectionsState) __);
}


/// Adds pattern-matching-related methods to [SectionsState].
extension SectionsStatePatterns on SectionsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( SectionsViewData view)?  loaded,TResult Function( ApiFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.view);case _Error() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( SectionsViewData view)  loaded,required TResult Function( ApiFailure failure)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.view);case _Error():
return error(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( SectionsViewData view)?  loaded,TResult? Function( ApiFailure failure)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.view);case _Error() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SectionsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SectionsState.initial()';
}


}




/// @nodoc


class _Loading implements SectionsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SectionsState.loading()';
}


}




/// @nodoc


class _Loaded implements SectionsState {
  const _Loaded(this.view);
  

 final  SectionsViewData view;

/// Create a copy of SectionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.view, view) || other.view == view));
}


@override
int get hashCode => Object.hash(runtimeType,view);

@override
String toString() {
  return 'SectionsState.loaded(view: $view)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $SectionsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 SectionsViewData view
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of SectionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? view = null,}) {
  return _then(_Loaded(
null == view ? _self.view : view // ignore: cast_nullable_to_non_nullable
as SectionsViewData,
  ));
}


}

/// @nodoc


class _Error implements SectionsState {
  const _Error(this.failure);
  

 final  ApiFailure failure;

/// Create a copy of SectionsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SectionsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SectionsStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 ApiFailure failure
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of SectionsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Error(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ApiFailure,
  ));
}


}

// dart format on
