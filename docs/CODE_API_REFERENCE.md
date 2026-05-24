# Code API Reference

Auto-generated reference of Dart source symbols (classes, top-level functions, and methods).

Generated at: 2026-05-16 14:16:28 UTC

## lib/main.dart

### Top-level Functions
- Future<void> main() async {

### Class AppBootstrapper
- State<AppBootstrapper> createState() => _AppBootstrapperState();

### Class _AppBootstrapperState
- double _displayProgress(double rawProgress) {
- void initState() {
- Future<AppServices> _startBootstrap() {
- setState(() {
- Widget build(BuildContext context) {
- FilledButton(

## lib/src/app/app_services.dart

### Class AppServices
- AppServices({
- static Future<AppServices> bootstrap() async {
- static Future<AppServices> bootstrapWithProgress({
- void Function(double progress, String message)? onProgress,
- static Future<AppServices> _bootstrapWithProgressImpl({
- void report(double progress, String message) {
- report(0.05, 'Preparing local storage');
- report(0.28, 'Starting network services');
- report(0.5, 'Preparing broker manager');
- report(0.72, 'Preparing background recovery');
- report(0.9, 'Finalizing import/export tools');
- report(1.0, 'Ready');

## lib/src/app/mqtt_hub_app.dart

### Class MqttHubApp
- Widget build(BuildContext context) {

## lib/src/app/startup_splash_screen.dart

### Top-level Functions
- void initState() {
- void dispose() {
- Widget build(BuildContext context) {

### Class StartupSplashScreen
- State<StartupSplashScreen> createState() => _StartupSplashScreenState();

### Class _StartupSplashScreenState
- No methods detected by heuristic parser.

## lib/src/localization/app_localizations.dart

### Class AppLocalizations
- AppLocalizations(this.locale);
- Locale('en'),
- Locale('ru'),
- Locale('es'),
- Locale('fr'),
- Locale('de'),
- Locale('zh'),
- Locale('ar'),
- static AppLocalizations of(BuildContext context) {
- _AppLocalizationsDelegate();
- String t(String key) {
- String importedConfigs(int count) =>
- t('importedConfigs').replaceAll('{count}', '$count');
- String deletePrompt(String name, int port) {
- String minutes(int value) {
- String uptime(Duration uptime) {
- String languageName(String code) {
- String nativeLanguageName(String code) {
- String statusLabel(BrokerStatus status) {
- String networkModeLabel(NetworkMode mode) {

### Class _AppLocalizationsDelegate
- bool isSupported(Locale locale) =>
- Future<AppLocalizations> load(Locale locale) async {
- bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {

## lib/src/models/broker_models.dart

### Class BrokerNetworkSettings
- BrokerNetworkSettings copyWith({
- Map<String, dynamic> toJson() => {

### Class BrokerSecuritySettings
- BrokerSecuritySettings copyWith({
- Map<String, dynamic> toJson() => {

### Class BrokerAutomationSettings
- BrokerAutomationSettings copyWith({
- Map<String, dynamic> toJson() => {

### Class BrokerLoggingSettings
- BrokerLoggingSettings copyWith({
- Map<String, dynamic> toJson() => {

### Class BrokerConfig
- BrokerConfig copyWith({
- BrokerConfig duplicate({required String id, required int port}) {
- Map<String, dynamic> toJson() => {

### Class BrokerLogEntry
- Map<String, dynamic> toJson() => {

### Class BrokerClientSnapshot
- No methods detected by heuristic parser.

### Class BrokerRuntimeState
- BrokerRuntimeState copyWith({

### Class NetworkSnapshot
- No methods detected by heuristic parser.

## lib/src/screens/about_debug_screen.dart

### Class AboutDebugScreen
- Widget build(BuildContext context) {
- Card(
- Text(l10n.t('about'), style: Theme.of(context).textTheme.titleLarge),
- Text(l10n.t('aboutText')),
- Text(
- Text(l10n.t('noRawPackets'))
- Padding(

## lib/src/screens/broker_details_screen.dart

### Class BrokerDetailsScreen
- Widget build(BuildContext context) {
- IconButton(
- Tab(text: l10n.t('overview')),
- Tab(text: l10n.t('logs')),
- Tab(text: l10n.t('settings')),
- _OverviewTab(broker: broker, runtime: runtime),
- _LogsTab(broker: broker),
- _SettingsTab(broker: broker),
- Future<void> _editBroker(BuildContext context, BrokerConfig broker) async {
- SnackBar(content: Text(context.l10n.t('portInUse'))),

### Class _OverviewTab
- Widget build(BuildContext context) {
- Card(
- Text(l10n.t('general'), style: Theme.of(context).textTheme.titleLarge),
- _Line(label: l10n.t('brokerName'), value: broker.name),
- _Line(label: l10n.t('description'), value: broker.description),
- _Line(label: l10n.t('port'), value: '${broker.network.port}'),
- _Line(label: l10n.t('localIp'), value: snapshot.primaryLocalAddress),
- _Line(
- Text(l10n.t('clients'), style: Theme.of(context).textTheme.titleLarge),
- Text(l10n.t('none'))
- _Line(label: 'Client ID', value: client.clientId),
- _Line(label: 'IP address', value: client.ipAddress),

### Class _LogsTab
- State<_LogsTab> createState() => _LogsTabState();

### Class _LogsTabState
- void dispose() {
- Widget build(BuildContext context) {
- Row(
- Expanded(
- IconButton(
- Wrap(
- ChoiceChip(
- Text(formatter.format(entry.timestamp)),
- Chip(label: Text(_directionLabel(context, entry.direction))),
- Text('${context.l10n.t('client')}: ${entry.clientId}'),
- Text(
- String _directionLabel(BuildContext context, BrokerLogDirection direction) {

### Class _SettingsTab
- Widget build(BuildContext context) {
- Card(
- Text(l10n.t('network'), style: Theme.of(context).textTheme.titleLarge),
- _Line(label: l10n.t('port'), value: '${broker.network.port}'),
- _Line(
- Text(l10n.t('security'), style: Theme.of(context).textTheme.titleLarge),
- Text(

### Class _Line
- Widget build(BuildContext context) {
- SizedBox(width: 150, child: Text(label)),
- Expanded(child: Text(value)),

## lib/src/screens/broker_list_screen.dart

### Class BrokerListScreen
- Widget build(BuildContext context) {
- Card(
- Text(
- Wrap(
- _Badge(
- _BrokerCard(
- Future<void> _confirmDelete(
- TextButton(
- FilledButton(

### Class _BrokerCard
- Widget build(BuildContext context) {
- Row(
- Expanded(
- Text(
- Text(config.description),
- Chip(
- Wrap(
- _Badge(label: l10n.t('port'), value: '${config.network.port}'),
- _Badge(label: l10n.t('localIp'), value: localIp),
- _Badge(label: l10n.t('publicIp'), value: publicIp),
- _Badge(
- OutlinedButton(onPressed: onOpen, child: Text(l10n.t('open'))),
- OutlinedButton(onPressed: onEdit, child: Text(l10n.t('edit'))),
- OutlinedButton(

### Class _Badge
- Widget build(BuildContext context) {
- Text(label, style: Theme.of(context).textTheme.bodySmall),
- Text(value, style: Theme.of(context).textTheme.labelLarge),

## lib/src/screens/dashboard_screen.dart

### Class DashboardScreen
- State<DashboardScreen> createState() => _DashboardScreenState();

### Class _DashboardScreenState
- Widget build(BuildContext context) {
- IconButton(
- BrokerListScreen(
- setState(() => _selectedIndex = index);
- NavigationDestination(
- Future<void> _createBroker() async {
- SnackBar(
- Future<void> _editBroker(String brokerId) async {
- SnackBar(content: Text(context.l10n.t('portInUse'))),
- void _openBroker(String brokerId) {

## lib/src/screens/import_export_screen.dart

### Class ImportExportScreen
- Widget build(BuildContext context) {
- Card(
- Text(
- Wrap(
- IconButton(
- Future<void> _importConfigs(BuildContext context) async {
- SnackBar(

## lib/src/screens/settings_screen.dart

### Class SettingsScreen
- Widget build(BuildContext context) {
- Card(
- Text(l10n.t('language'), style: Theme.of(context).textTheme.titleLarge),
- Text(l10n.t('maxBrokers'), style: Theme.of(context).textTheme.titleLarge),
- _StepperTile(
- Text(
- Text(l10n.t('maxLogEntries'), style: Theme.of(context).textTheme.titleLarge),
- Text(l10n.t('appliesToNewBrokers')),

### Class _StepperTile
- Widget build(BuildContext context) {
- IconButton(
- Expanded(

## lib/src/services/background_service_manager.dart

### Top-level Functions
- void _runSafe(Future<void> Function() task) {
- Future<void> initialize() async {
- void didChangeAppLifecycleState(AppLifecycleState state) {
- void dispose() {

### Class BackgroundServiceManager
- No methods detected by heuristic parser.

## lib/src/services/broker_manager.dart

### Class BrokerManager
- BrokerManager({
- Future<void> initialize() async {
- notifyListeners();
- BrokerRuntimeState runtimeFor(String brokerId) {
- BrokerConfig? brokerById(String brokerId) => _configs[brokerId];
- Future<void> createBroker(BrokerConfig config) async {
- Future<void> updateBroker(BrokerConfig config) async {
- Future<void> duplicateBroker(String brokerId) async {
- Future<void> deleteBroker(String brokerId) async {
- Future<void> startBroker(String brokerId) async {
- Future<void> stopBroker(
- Future<void> restartBroker(String brokerId) async {
- Future<void> importConfigs(List<BrokerConfig> configs) async {
- Future<void> recoverAfterWake() async {
- bool portInUse(int port) {
- int nextAvailablePort({int startingFrom = 1883}) {
- String newBrokerId() => _newId();
- BrokerConfig newDraftBroker({int? defaultMaxLogEntries}) {
- Future<void> applyGlobalLogLimit(int maxEntries) async {
- String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

## lib/src/services/import_export_service.dart

### Class ImportExportService
- Future<void> exportBrokerConfig(BrokerConfig config) async {
- ShareParams(title: 'Export ${config.name}', files: [XFile(file.path)]),
- Future<void> exportAllBrokers(List<BrokerConfig> configs) async {
- ShareParams(title: 'Export all brokers', files: [XFile(file.path)]),
- Future<void> exportBrokerLogs({
- ShareParams(title: 'Export broker logs', files: [XFile(file.path)]),
- Future<List<BrokerConfig>> importBrokerConfigs() async {
- Future<File> _writeJsonFile({

## lib/src/services/log_manager.dart

### Class LogManager
- UnmodifiableListView<BrokerLogEntry> logsFor(String brokerId) {
- void append(
- notifyListeners();
- void clear(String brokerId) {
- Map<String, dynamic> exportPayload(

## lib/src/services/mqtt_broker.dart

### Class EmbeddedMqttBroker
- EmbeddedMqttBroker({
- Future<void> start() async {
- _setState(
- _scheduleAutoStop();
- _fail('Broker socket error: $error');
- _fail('Failed to start broker on port ${config.network.port}: $error');
- Future<void> stop({String reason = 'Stopped by user'}) async {
- Future<void> dispose() async {
- void _scheduleAutoStop() {
- Duration(minutes: config.automation.autoStopMinutes),
- void _handleIncomingSocket(Socket socket) {
- _emitState();
- _disconnect(connection, 'Socket error: $error');
- _disconnect(connection, 'Client disconnected.');
- void _handleData(_ClientConnection connection, Uint8List data) {
- _touch();
- _logRaw(connection, data, incoming: true);
- _processPacket(connection, packet);
- void _processPacket(_ClientConnection connection, _MqttPacket packet) {
- _handleConnect(connection, packet.body);
- _handlePublish(connection, packet);
- _handlePubAck(connection, packet.body);
- _handleSubscribe(connection, packet.body);
- _handleUnsubscribe(connection, packet.body);
- _sendPacket(
- _disconnect(connection, 'Client sent DISCONNECT.');
- void _handleConnect(_ClientConnection connection, Uint8List body) {
- _sendConnAck(connection, 0x02);
- _sendConnAck(connection, 0x01);
- _sendConnAck(connection, 0x05);
- _disconnect(other, 'Duplicate client ID: ${clientId.value}.');
- _startKeepAliveMonitor(connection);
- _sendConnAck(connection, 0x00);
- _disconnect(connection, 'CONNECT parse error: $error');
- bool _authorizeClient(String clientId, String username, String password) {
- void _handleSubscribe(_ClientConnection connection, Uint8List body) {
- _addSubscription(connection, topic.value, requestedQos);
- _publishToConnection(
- void _handleUnsubscribe(_ClientConnection connection, Uint8List body) {
- _removeSubscription(connection, topic.value);
- void _handlePublish(_ClientConnection connection, _MqttPacket packet) {
- _fanOutPublish(
- void _handlePubAck(_ClientConnection connection, Uint8List body) {
- void _fanOutPublish({
- void _publishToConnection(
- void _addSubscription(_ClientConnection connection, String topic, int qos) {
- _removeSubscription(connection, topic);
- void _removeSubscription(_ClientConnection connection, String topic) {
- Future<void> _disconnect(
- void _startKeepAliveMonitor(_ClientConnection connection) {
- _disconnect(connection, 'KeepAlive timeout.');
- void _sendConnAck(_ClientConnection connection, int returnCode) {
- void _sendPacket(
- _logRaw(connection, Uint8List.fromList(bytes), incoming: false);
- void _logRaw(
- List<int> _encodeRemainingLength(int length) {
- bool _topicMatches(String filter, String topic) {
- int _nextPacketId() {
- String _toHex(Uint8List bytes) {
- void _touch() {
- _setState(_state.copyWith(lastActivityAt: DateTime.now()));
- void _emitState() {
- void _setState(BrokerRuntimeState state) {
- onStateChanged(_state);
- void _fail(String message) {

### Class _ClientConnection
- _ClientConnection({

### Class _Subscription
- No methods detected by heuristic parser.

### Class _RetainedMessage
- No methods detected by heuristic parser.

### Class _MqttPacket
- No methods detected by heuristic parser.

### Class _ReadStringResult
- No methods detected by heuristic parser.

### Class _ReadBytesResult
- No methods detected by heuristic parser.

## lib/src/services/network_manager.dart

### Class NetworkManager
- Future<void> initialize() async {
- _safeRefresh();
- void _safeRefresh() {
- unawaited(() async {
- Future<void> refresh() async {
- notifyListeners();
- Future<List<String>> _loadLocalAddresses() async {
- Future<String?> _safeWifiName() async {
- Future<String?> _loadPublicAddress() async {
- NetworkMode _detectMode(
- void dispose() {

## lib/src/services/settings_manager.dart

### Class SettingsManager
- SettingsManager({required StorageManager storageManager})
- Future<void> initialize() async {
- notifyListeners();
- Future<void> updateLanguageCode(String value) async {
- Future<void> updateMaxBrokers(int value) async {
- Future<void> updateMessageRetentionHours(int value) async {
- Future<void> updateMaxLogEntries(int value) async {

## lib/src/services/storage_manager.dart

### Class StorageManager
- Future<void> initialize() async {
- Future<Database> _openDatabase(String databasePath) {
- Future<List<BrokerConfig>> loadBrokerConfigs() async {
- jsonDecode(row['payload']! as String) as Map<String, dynamic>,
- Future<void> saveBrokerConfig(BrokerConfig config) async {
- Future<void> deleteBrokerConfig(String id) async {
- Future<void> saveStringSetting(String key, String value) async {
- Future<String?> loadStringSetting(String key) async {
- Future<void> saveIntSetting(String key, int value) async {
- Future<int?> loadIntSetting(String key) async {

## lib/src/widgets/broker_editor_sheet.dart

### Top-level Functions
- Future<BrokerConfig?> showBrokerEditorSheet(

### Class BrokerEditorSheet
- State<BrokerEditorSheet> createState() => _BrokerEditorSheetState();

### Class _BrokerEditorSheetState
- void initState() {
- void dispose() {
- Widget build(BuildContext context) {
- Text(l10n.t('brokerSettings'), style: theme.textTheme.headlineSmall),
- TextField(
- _SectionLabel(title: l10n.t('network')),
- SwitchListTile(
- setState(() => _externalAccessEnabled = value),
- _SectionLabel(title: l10n.t('security')),
- _SectionLabel(title: l10n.t('automationLogging')),
- _SectionLabel(title: l10n.t('logging')),
- Row(
- Expanded(
- void _save() {
- List<String> _splitList(String value) {

### Class _SectionLabel
- Widget build(BuildContext context) {
