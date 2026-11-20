// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sites_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SitesEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SitesEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesEvent()';
}


}

/// @nodoc
class $SitesEventCopyWith<$Res>  {
$SitesEventCopyWith(SitesEvent _, $Res Function(SitesEvent) __);
}


/// Adds pattern-matching-related methods to [SitesEvent].
extension SitesEventPatterns on SitesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Fetch value)?  fetch,TResult Function( _Refresh value)?  refresh,TResult Function( _Select value)?  select,TResult Function( _TenantUpdated value)?  tenantUpdated,TResult Function( _Reset value)?  reset,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch(_that);case _Refresh() when refresh != null:
return refresh(_that);case _Select() when select != null:
return select(_that);case _TenantUpdated() when tenantUpdated != null:
return tenantUpdated(_that);case _Reset() when reset != null:
return reset(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Fetch value)  fetch,required TResult Function( _Refresh value)  refresh,required TResult Function( _Select value)  select,required TResult Function( _TenantUpdated value)  tenantUpdated,required TResult Function( _Reset value)  reset,}){
final _that = this;
switch (_that) {
case _Fetch():
return fetch(_that);case _Refresh():
return refresh(_that);case _Select():
return select(_that);case _TenantUpdated():
return tenantUpdated(_that);case _Reset():
return reset(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Fetch value)?  fetch,TResult? Function( _Refresh value)?  refresh,TResult? Function( _Select value)?  select,TResult? Function( _TenantUpdated value)?  tenantUpdated,TResult? Function( _Reset value)?  reset,}){
final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch(_that);case _Refresh() when refresh != null:
return refresh(_that);case _Select() when select != null:
return select(_that);case _TenantUpdated() when tenantUpdated != null:
return tenantUpdated(_that);case _Reset() when reset != null:
return reset(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetch,TResult Function()?  refresh,TResult Function( String slug)?  select,TResult Function( TenantModel tenant)?  tenantUpdated,TResult Function()?  reset,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch();case _Refresh() when refresh != null:
return refresh();case _Select() when select != null:
return select(_that.slug);case _TenantUpdated() when tenantUpdated != null:
return tenantUpdated(_that.tenant);case _Reset() when reset != null:
return reset();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetch,required TResult Function()  refresh,required TResult Function( String slug)  select,required TResult Function( TenantModel tenant)  tenantUpdated,required TResult Function()  reset,}) {final _that = this;
switch (_that) {
case _Fetch():
return fetch();case _Refresh():
return refresh();case _Select():
return select(_that.slug);case _TenantUpdated():
return tenantUpdated(_that.tenant);case _Reset():
return reset();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetch,TResult? Function()?  refresh,TResult? Function( String slug)?  select,TResult? Function( TenantModel tenant)?  tenantUpdated,TResult? Function()?  reset,}) {final _that = this;
switch (_that) {
case _Fetch() when fetch != null:
return fetch();case _Refresh() when refresh != null:
return refresh();case _Select() when select != null:
return select(_that.slug);case _TenantUpdated() when tenantUpdated != null:
return tenantUpdated(_that.tenant);case _Reset() when reset != null:
return reset();case _:
  return null;

}
}

}

/// @nodoc


class _Fetch implements SitesEvent {
  const _Fetch();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Fetch);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesEvent.fetch()';
}


}




/// @nodoc


class _Refresh implements SitesEvent {
  const _Refresh();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Refresh);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesEvent.refresh()';
}


}




/// @nodoc


class _Select implements SitesEvent {
  const _Select(this.slug);
  

 final  String slug;

/// Create a copy of SitesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectCopyWith<_Select> get copyWith => __$SelectCopyWithImpl<_Select>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Select&&(identical(other.slug, slug) || other.slug == slug));
}


@override
int get hashCode => Object.hash(runtimeType,slug);

@override
String toString() {
  return 'SitesEvent.select(slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$SelectCopyWith<$Res> implements $SitesEventCopyWith<$Res> {
  factory _$SelectCopyWith(_Select value, $Res Function(_Select) _then) = __$SelectCopyWithImpl;
@useResult
$Res call({
 String slug
});




}
/// @nodoc
class __$SelectCopyWithImpl<$Res>
    implements _$SelectCopyWith<$Res> {
  __$SelectCopyWithImpl(this._self, this._then);

  final _Select _self;
  final $Res Function(_Select) _then;

/// Create a copy of SitesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? slug = null,}) {
  return _then(_Select(
null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _TenantUpdated implements SitesEvent {
  const _TenantUpdated(this.tenant);
  

 final  TenantModel tenant;

/// Create a copy of SitesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantUpdatedCopyWith<_TenantUpdated> get copyWith => __$TenantUpdatedCopyWithImpl<_TenantUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantUpdated&&(identical(other.tenant, tenant) || other.tenant == tenant));
}


@override
int get hashCode => Object.hash(runtimeType,tenant);

@override
String toString() {
  return 'SitesEvent.tenantUpdated(tenant: $tenant)';
}


}

/// @nodoc
abstract mixin class _$TenantUpdatedCopyWith<$Res> implements $SitesEventCopyWith<$Res> {
  factory _$TenantUpdatedCopyWith(_TenantUpdated value, $Res Function(_TenantUpdated) _then) = __$TenantUpdatedCopyWithImpl;
@useResult
$Res call({
 TenantModel tenant
});




}
/// @nodoc
class __$TenantUpdatedCopyWithImpl<$Res>
    implements _$TenantUpdatedCopyWith<$Res> {
  __$TenantUpdatedCopyWithImpl(this._self, this._then);

  final _TenantUpdated _self;
  final $Res Function(_TenantUpdated) _then;

/// Create a copy of SitesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tenant = null,}) {
  return _then(_TenantUpdated(
null == tenant ? _self.tenant : tenant // ignore: cast_nullable_to_non_nullable
as TenantModel,
  ));
}


}

/// @nodoc


class _Reset implements SitesEvent {
  const _Reset();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reset);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesEvent.reset()';
}


}




/// @nodoc
mixin _$SitesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SitesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesState()';
}


}

/// @nodoc
class $SitesStateCopyWith<$Res>  {
$SitesStateCopyWith(SitesState _, $Res Function(SitesState) __);
}


/// Adds pattern-matching-related methods to [SitesState].
extension SitesStatePatterns on SitesState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( SitesData data)?  loaded,TResult Function( ApiFailure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.data);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( SitesData data)  loaded,required TResult Function( ApiFailure failure)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.data);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( SitesData data)?  loaded,TResult? Function( ApiFailure failure)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.data);case _Error() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SitesState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesState.initial()';
}


}




/// @nodoc


class _Loading implements SitesState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SitesState.loading()';
}


}




/// @nodoc


class _Loaded implements SitesState {
  const _Loaded(this.data);
  

 final  SitesData data;

/// Create a copy of SitesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.data, data) || other.data == data));
}


@override
int get hashCode => Object.hash(runtimeType,data);

@override
String toString() {
  return 'SitesState.loaded(data: $data)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $SitesStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 SitesData data
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of SitesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_Loaded(
null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SitesData,
  ));
}


}

/// @nodoc


class _Error implements SitesState {
  const _Error(this.failure);
  

 final  ApiFailure failure;

/// Create a copy of SitesState
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
  return 'SitesState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SitesStateCopyWith<$Res> {
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

/// Create a copy of SitesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(_Error(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ApiFailure,
  ));
}


}

// dart format on
