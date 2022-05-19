import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/pages/explore/app_banner.dart';
import 'package:software/pages/explore/app_dialog.dart';
import 'package:software/pages/explore/app_grid.dart';
import 'package:software/pages/explore/explore_model.dart';
import 'package:software/pages/snap_section.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({Key? key}) : super(key: key);

  static Widget create(BuildContext context) {
    final client = context.read<SnapdClient>();
    return ChangeNotifierProvider(
      create: (_) => ExploreModel(client),
      child: const ExplorePage(),
    );
  }

  static Widget createTitle(BuildContext context) =>
      Text(context.l10n.explorePageTitle);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    final width = MediaQuery.of(context).size.width;
    return YaruPage(children: [
      if (width < 1000) _AppBannerCarousel(),
      Padding(
        padding: EdgeInsets.only(
            left: 10, right: 0, top: width < 1000 ? 30 : 0, bottom: 10),
        child: ChangeNotifierProvider.value(value: model, child: _FilterBar()),
      ),
      if (model.searchActive) _SearchField(),
      if (model.searchActive)
        AppGrid(
          topPadding: 0,
          name: model.searchQuery,
          findByName: true,
        ),
      if (!model.searchActive)
        for (int i = 0; i < model.filters.entries.length; i++)
          if (model.filters.entries.elementAt(i).value == true)
            AppGrid(
              topPadding: i == 0 ? 10 : 20,
              name: model.filters.entries.elementAt(i).key.title(),
              headline: model.filters.entries.elementAt(i).key.title(),
              findByName: false,
            ),
    ]);
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({Key? key}) : super(key: key);

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 50),
      child: TextField(
        controller: _controller,
        onChanged: (value) => model.searchQuery = value,
        autofocus: true,
        decoration: InputDecoration(
          prefixIcon: model.searchQuery == ''
              ? null
              : IconButton(
                  splashRadius: 20,
                  onPressed: () {
                    model.searchQuery = '';
                    _controller.text = '';
                  },
                  icon: Icon(YaruIcons.edit_clear)),
          isDense: false,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({Key? key}) : super(key: key);

  @override
  State<_FilterBar> createState() => __FilterBarState();
}

class __FilterBarState extends State<_FilterBar> {
  final ScrollController _controller = ScrollController();
  double _position = 0;
  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: IconButton(
            splashRadius: 20,
            onPressed: () => model.searchActive = !model.searchActive,
            icon: Icon(
              YaruIcons.search,
              color: model.searchActive
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        SizedBox(
          height: 20,
          child: VerticalDivider(
            thickness: 1,
            width: 20,
            color: Theme.of(context).dividerColor,
          ),
        ),
        IconButton(
          onPressed: () {
            if (_position >= 1) _position -= 50;
            _controller.animateTo(
              _position,
              duration: Duration(milliseconds: 50),
              curve: Curves.linear,
            );
          },
          icon: Icon(YaruIcons.go_previous),
          splashRadius: 20,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final section in SnapSection.values)
                  SizedBox(
                    width: 50,
                    child: _FilterPill(
                        onPressed: () =>
                            model.setFilter(snapSections: [section]),
                        selected: model.filters[section]!,
                        iconData: snapSectionToIcon[section]!),
                  )
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            _position += 50;
            _controller.animateTo(
              _position,
              duration: Duration(milliseconds: 50),
              curve: Curves.linear,
            );
          },
          icon: Icon(YaruIcons.go_next),
          splashRadius: 20,
        ),
      ],
    );
  }
}

class _AppBannerCarousel extends StatelessWidget {
  const _AppBannerCarousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = context.read<ExploreModel>();
    final size = MediaQuery.of(context).size;
    return FutureBuilder<List<Snap>>(
      future: model.findSnapsBySection(section: 'featured'),
      builder: (context, snapshot) => snapshot.hasData
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: YaruCarousel(
                placeIndicator: false,
                autoScrollDuration: Duration(seconds: 3),
                width: size.width - 30,
                height: 178,
                autoScroll: true,
                children: snapshot.data!
                    .take(10)
                    .map(
                      (snap) => AppBanner(
                        snap: snap,
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => ChangeNotifierProvider.value(
                            value: model,
                            child: AppDialog(snap: snap),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: YaruCircularProgressIndicator(),
              ),
            ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData iconData;
  final bool selected;
  final Function()? onPressed;

  _FilterPill({
    Key? key,
    required this.selected,
    required this.iconData,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 20,
      onPressed: onPressed,
      icon: Icon(
        iconData,
        color: selected
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
      ),
    );
  }
}
