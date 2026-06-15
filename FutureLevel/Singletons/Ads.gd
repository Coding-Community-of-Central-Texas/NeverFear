extends Node

const GAME_OVER_INTERSTITIAL_ANDROID := "ca-app-pub-9308215462399709/5241273291"
const GAME_OVER_INTERSTITIAL_IOS_RELEASE := "ca-app-pub-9308215462399709/7094493165"
const GAME_OVER_INTERSTITIAL_IOS_TEST := "ca-app-pub-3940256099942544/4411468910"
const ADMOB_SINGLETON := "PoingGodotAdMob"
const INTERSTITIAL_SINGLETON := "PoingGodotAdMobInterstitialAd"
const CONSENT_INFORMATION_SINGLETON := "PoingGodotAdMobConsentInformation"
const USER_MESSAGING_PLATFORM_SINGLETON := "PoingGodotAdMobUserMessagingPlatform"

var _initialized := false
var _initialization_started := false
var _consent_checked := false
var _consent_update_in_progress := false
var _is_loading := false
var _is_showing := false
var _last_ad_error := ""
var _interstitial_ad: InterstitialAd = null
var _showing_interstitial_ad: InterstitialAd = null
var _pending_finished_callback: Callable = Callable()
var _initialization_listener := OnInitializationCompleteListener.new()
var _interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var _full_screen_callback := FullScreenContentCallback.new()
var _logged_ad_mode_for_platform: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ads_callbacks()
	prepare_game_over_ad()

func is_available() -> bool:
	return _is_supported_platform() \
		and Engine.has_singleton(ADMOB_SINGLETON) \
		and Engine.has_singleton(INTERSTITIAL_SINGLETON)

func initialize_ads() -> void:
	if not is_available() or _initialized or _initialization_started:
		return

	if _should_update_consent_before_ads():
		_update_consent_before_ads()
		return

	_initialize_mobile_ads()

func load_interstitial() -> void:
	if not is_available() or _is_loading or _interstitial_ad != null or _is_showing:
		return

	if not _initialized:
		initialize_ads()
		return

	var ad_unit_id := _get_game_over_interstitial_id()
	if ad_unit_id.is_empty():
		return

	_is_loading = true
	_last_ad_error = ""
	_log_ad_mode()
	InterstitialAdLoader.new().load(
		ad_unit_id,
		AdRequest.new(),
		_interstitial_ad_load_callback
	)

func is_interstitial_ready() -> bool:
	return is_available() and _interstitial_ad != null and not _is_showing

func show_interstitial(on_finished: Callable = Callable()) -> void:
	if _is_showing:
		return

	_pending_finished_callback = on_finished

	if not is_available():
		_last_ad_error = "AdMob plugin is not available on %s." % OS.get_name()
		_finish_ad_flow()
		return

	if not _initialized:
		initialize_ads()
		_finish_ad_flow()
		return

	if not is_interstitial_ready():
		_last_ad_error = "Interstitial ad is not ready."
		_finish_ad_flow()
		load_interstitial()
		return

	_is_showing = true
	_showing_interstitial_ad = _interstitial_ad
	_interstitial_ad = null
	_showing_interstitial_ad.show()

func get_last_ad_error() -> String:
	return _last_ad_error

func prepare_game_over_ad() -> void:
	initialize_ads()
	load_interstitial()

func show_game_over_interstitial(on_finished: Callable) -> void:
	show_interstitial(on_finished)

func _setup_ads_callbacks() -> void:
	_initialization_listener.on_initialization_complete = _on_ads_initialization_complete

	_interstitial_ad_load_callback.on_ad_failed_to_load = _on_interstitial_ad_failed_to_load
	_interstitial_ad_load_callback.on_ad_loaded = _on_interstitial_ad_loaded

	_full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		_on_interstitial_closed()

	_full_screen_callback.on_ad_failed_to_show_full_screen_content = func(_ad_error: AdError) -> void:
		_last_ad_error = _format_ad_error(_ad_error)
		_on_interstitial_closed()

func _is_supported_platform() -> bool:
	var platform := OS.get_name()
	return platform == "Android" or platform == "iOS"

func _initialize_mobile_ads() -> void:
	if _initialization_started or _initialized:
		return

	_initialization_started = true
	MobileAds.initialize(_initialization_listener)

func _on_ads_initialization_complete(_initialization_status: InitializationStatus) -> void:
	_initialized = true
	_initialization_started = false
	load_interstitial()

func _should_update_consent_before_ads() -> bool:
	return OS.get_name() == "iOS" \
		and not _consent_checked \
		and not _consent_update_in_progress \
		and Engine.has_singleton(CONSENT_INFORMATION_SINGLETON) \
		and Engine.has_singleton(USER_MESSAGING_PLATFORM_SINGLETON)

func _update_consent_before_ads() -> void:
	_consent_update_in_progress = true

	var request_parameters := ConsentRequestParameters.new()
	UserMessagingPlatform.consent_information.update(
		request_parameters,
		_on_consent_info_updated,
		_on_consent_info_update_failed
	)

func _on_consent_info_updated() -> void:
	_consent_checked = true
	_consent_update_in_progress = false

	var consent_information := UserMessagingPlatform.consent_information
	if consent_information.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED \
			and consent_information.get_is_consent_form_available():
		UserMessagingPlatform.load_consent_form(
			_on_consent_form_loaded,
			_on_consent_form_load_failed
		)
		return

	_initialize_mobile_ads()

func _on_consent_info_update_failed(form_error: FormError) -> void:
	_consent_checked = true
	_consent_update_in_progress = false
	_last_ad_error = _format_form_error(form_error)
	push_warning("Ads: Consent info update failed; continuing without blocking ads initialization. %s" % _last_ad_error)
	_initialize_mobile_ads()

func _on_consent_form_loaded(consent_form: ConsentForm) -> void:
	consent_form.show(_on_consent_form_dismissed)

func _on_consent_form_load_failed(form_error: FormError) -> void:
	_last_ad_error = _format_form_error(form_error)
	push_warning("Ads: Consent form failed to load; continuing without blocking ads initialization. %s" % _last_ad_error)
	_initialize_mobile_ads()

func _on_consent_form_dismissed(form_error: FormError) -> void:
	if form_error != null:
		_last_ad_error = _format_form_error(form_error)
		push_warning("Ads: Consent form dismissed with an error. %s" % _last_ad_error)

	_initialize_mobile_ads()

func _on_interstitial_ad_failed_to_load(ad_error: LoadAdError) -> void:
	_is_loading = false
	_last_ad_error = _format_ad_error(ad_error)
	push_warning("Ads: Interstitial failed to load. %s" % _last_ad_error)

func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	_is_loading = false
	_last_ad_error = ""
	_destroy_loaded_interstitial()
	_interstitial_ad = ad
	_interstitial_ad.full_screen_content_callback = _full_screen_callback

func _on_interstitial_closed() -> void:
	_destroy_showing_interstitial()
	_finish_ad_flow()
	load_interstitial()

func _finish_ad_flow() -> void:
	var callback := _pending_finished_callback
	_pending_finished_callback = Callable()
	_is_showing = false

	if callback.is_valid():
		callback.call_deferred()

func _get_game_over_interstitial_id() -> String:
	match OS.get_name():
		"Android":
			return GAME_OVER_INTERSTITIAL_ANDROID
		"iOS":
			return GAME_OVER_INTERSTITIAL_IOS_TEST if OS.is_debug_build() else GAME_OVER_INTERSTITIAL_IOS_RELEASE
		_:
			return ""

func _log_ad_mode() -> void:
	var platform := OS.get_name()
	if _logged_ad_mode_for_platform.get(platform, false):
		return

	_logged_ad_mode_for_platform[platform] = true
	if platform == "iOS":
		var mode := "test" if OS.is_debug_build() else "production"
		print("Ads: iOS %s interstitial mode active." % mode)
	elif platform == "Android":
		print("Ads: Android interstitial mode active using existing configuration.")

func _format_ad_error(ad_error: AdError) -> String:
	if ad_error == null:
		return "No error details were provided."

	return "code=%d domain=%s message=%s" % [ad_error.code, ad_error.domain, ad_error.message]

func _format_form_error(form_error: FormError) -> String:
	if form_error == null:
		return "No error details were provided."

	return "code=%d message=%s" % [form_error.error_code, form_error.message]

func _destroy_loaded_interstitial() -> void:
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
		_interstitial_ad = null

func _destroy_showing_interstitial() -> void:
	if _showing_interstitial_ad != null:
		_showing_interstitial_ad.destroy()
		_showing_interstitial_ad = null
	_is_showing = false

func _exit_tree() -> void:
	_destroy_loaded_interstitial()
	_destroy_showing_interstitial()
