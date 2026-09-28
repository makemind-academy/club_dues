import 'dart:async';
import 'dart:convert';

import 'package:mcp_server/mcp_server.dart';

import 'serve_bundle.dart';

/// dues_server — who has paid this month, and who has not.
///
/// This is the smallest sample in the series on purpose. The article it belongs
/// to claims that a person who does not write code can make their own small
/// thing, and the only honest way to support that claim is to keep the thing
/// small enough that its size can be read off the page.
///
/// So: no framework, no persistence, no accounts. A list of names, a set of who
/// paid, and a total. Everything else would be somebody else's requirement.
void main(List<String> args) async {
  const config = McpServerConfig(
    name: 'Club Dues',
    version: '1.0.0',
    capabilities: ServerCapabilities(
      tools: ToolsCapability(listChanged: true),
      resources: ResourcesCapability(listChanged: true),
    ),
  );
  final server = McpServer.createServer(config);
  DuesServer(server).register();
  // The screen next door: AppPlayer reads it from here and sends the pages'
  // tool calls back to the tools above.
  registerBundleUi(server, '../dues.mbd');
  final transport = McpServer.createStdioTransport().get();
  server.connect(transport);
  await Completer<void>().future;
}

class DuesServer {
  DuesServer(this.server);

  final Server server;

  static const _fee = 2000; // cents
  static const _members = [
    'Oliver', 'Amelia', 'Harry', 'Isla', 'Jack', 'Ava', 'George', 'Mia',
  ];
  final _paid = <String>{'Oliver', 'Harry', 'Jack'};

  void register() {
    server.addTool(
      name: 'dues.list',
      description: 'Who has paid this month and who has not, with the total',
      inputSchema: const {'type': 'object', 'properties': {}},
      handler: (args) async => _state(),
    );

    server.addTool(
      name: 'dues.toggle',
      description: 'Mark one member paid or unpaid',
      inputSchema: const {
        'type': 'object',
        'properties': {
          'who': {'type': 'string'},
        },
        'required': ['who'],
      },
      handler: (args) async {
        final who = args['who'] as String;
        if (!_members.contains(who)) return _state(notice: 'no member $who');
        // Toggle, not set. The person using this is standing at a football
        // pitch with one hand free.
        _paid.contains(who) ? _paid.remove(who) : _paid.add(who);
        return _state(notice: '$who ${_paid.contains(who) ? "paid" : "unpaid"}');
      },
    );
  }

  CallToolResult _state({String notice = ''}) => CallToolResult(content: [
        TextContent(
          text: jsonEncode({
            'rows': _members
                .map((m) => {
                      'name': m,
                      'paid': _paid.contains(m),
                      'mark': _paid.contains(m) ? 'paid' : '-',
                    })
                .toList(),
            'paidCount': _paid.length,
            'total': _members.length,
            'collected': '\$${(_paid.length * _fee / 100).toStringAsFixed(0)}',
            'owed': '\$${((_members.length - _paid.length) * _fee / 100).toStringAsFixed(0)}',
            'notice': notice,
          }),
        )
      ]);
}
