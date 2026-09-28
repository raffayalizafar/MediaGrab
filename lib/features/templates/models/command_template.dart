/// Custom command template entity inspired by Seal's CommandTemplate Room entity.
class CommandTemplate {
  final String id;
  final String name;
  final String description;
  final String templateArgs;
  final bool isBuiltIn;

  const CommandTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.templateArgs,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'template_args': templateArgs,
    'is_built_in': isBuiltIn,
  };

  factory CommandTemplate.fromJson(Map<String, dynamic> json) =>
      CommandTemplate(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Untitled Template',
        description: json['description'] as String? ?? '',
        templateArgs: json['template_args'] as String? ?? '',
        isBuiltIn: json['is_built_in'] as bool? ?? false,
      );

  static List<CommandTemplate> get defaultTemplates => [
    const CommandTemplate(
      id: 'builtin_1',
      name: '1080p Video + Subtitles',
      description:
          'Downloads 1080p resolution and embeds all available subtitles.',
      templateArgs: '-S res:1080 --write-subs --embed-subs --sub-langs all',
      isBuiltIn: true,
    ),
    const CommandTemplate(
      id: 'builtin_2',
      name: 'HQ Audio MP3 + Cover Art',
      description:
          'Extracts 320k MP3 audio, embeds cover thumbnail and ID3 tags.',
      templateArgs:
          '-x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata',
      isBuiltIn: true,
    ),
    const CommandTemplate(
      id: 'builtin_3',
      name: 'Playlist Subfolder Archive',
      description: 'Saves playlist items numbered inside a named folder.',
      templateArgs:
          '-o "%(playlist_title)s/%(playlist_index)s - %(title)s.%(ext)s"',
      isBuiltIn: true,
    ),
    const CommandTemplate(
      id: 'builtin_4',
      name: 'SponsorBlock (Auto-Remove Ads)',
      description: 'Removes sponsor segments and intro cards automatically.',
      templateArgs: '--sponsorblock-remove all',
      isBuiltIn: true,
    ),
    const CommandTemplate(
      id: 'builtin_5',
      name: 'Fast aria2c Acceleration',
      description: 'Accelerates downloads with 16 multi-threaded connections.',
      templateArgs:
          '--downloader aria2c --downloader-args "aria2c:-s 16 -x 16 -k 1M"',
      isBuiltIn: true,
    ),
  ];
}
