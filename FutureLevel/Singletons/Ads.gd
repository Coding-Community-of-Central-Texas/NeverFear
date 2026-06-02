extends Node

const GAME_OVER_INTERSTITIAL_ANDROID := "ca-app-pub-9308215462399709/5241273291"
const ADMOB_SINGLETON := "PoingGodotAdMob"
const INTERSTITIAL_SINGLETON := "PoingGodotAdMobInterstitialAd"

var _initialized := false
var _is_loading := false
var _interstitial_ad: InterstitialAd = null
var _showing_interstitial_ad: InterstitialAd = null
var _pending_finished_callback: Callable = Callable()
var _interstitial_ad_load_callback := InterstitialAdLoadCallback.new()
var _full_screen_callback := FullScreenContentCallback.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_interstitial_callbacks()
	prepare_game_over_ad()

func is_available() -> bool:
	return OS.get_name() == "Android" \
		and Engine.has_singleton(ADMOB_SINGLETON) \
		and Engine.has_singleton(INTERSTITIAL_SINGLETON)

func prepare_game_over_ad() -> void:
	if not is_available():
		return

	if not _initialized:
		MobileAds.initialize()
		_initialized = true

	_load_interstitial()

func show_game_over_interstitial(on_finished: Callable) -> void:
	_pending_finished_callback = on_finished

	if not is_available():
		_finish_ad_flow()
		return

	prepare_game_over_ad()

	if _interstitial_ad == null:
		_finish_ad_flow()
		_load_interstitial()
		return

	_showing_interstitial_ad = _interstitial_ad
	_interstitial_ad = null
	_showing_interstitial_ad.show()

func _setup_interstitial_callbacks() -> void:
	_interstitial_ad_load_callback.on_ad_failed_to_load = _on_interstitial_ad_failed_to_load
	_interstitial_ad_load_callback.on_ad_loaded = _on_interstitial_ad_loaded

	_full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
		_on_interstitial_closed()

	_full_screen_callback.on_ad_failed_to_show_full_screen_content = func(_ad_error: AdError) -> void:
		_on_interstitial_closed()

func _load_interstitial() -> void:
	if not is_available() or _is_loading or _interstitial_ad != null:
		return

	_is_loading = true
	InterstitialAdLoader.new().load(
		GAME_OVER_INTERSTITIAL_ANDROID,
		AdRequest.new(),
		_interstitial_ad_load_callback
	)

func _on_interstitial_ad_failed_to_load(_ad_error: LoadAdError) -> void:
	_is_loading = false

func _on_interstitial_ad_loaded(ad: InterstitialAd) -> void:
	_is_loading = false
	_destroy_loaded_interstitial()
	_interstitial_ad = ad
	_interstitial_ad.full_screen_content_callback = _full_screen_callback

func _on_interstitial_closed() -> void:
	_destroy_showing_interstitial()
	_finish_ad_flow()
	_load_interstitial()

func _finish_ad_flow() -> void:
	var callback := _pending_finished_callback
	_pending_finished_callback = Callable()

	if callback.is_valid():
		callback.call_deferred()

func _destroy_loaded_interstitial() -> void:
	if _interstitial_ad != null:
		_interstitial_ad.destroy()
		_interstitial_ad = null

func _destroy_showing_interstitial() -> void:
	if _showing_interstitial_ad != null:
		_showing_interstitial_ad.destroy()
		_showing_interstitial_ad = null

func _exit_tree() -> void:
	_destroy_loaded_interstitial()
	_destroy_showing_interstitial()
