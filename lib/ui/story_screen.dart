import 'package:flutter/material.dart';

import '../engine/game.dart';
import '../models/story.dart';
import '../models/units.dart';
import '../profile.dart';
import '../story/badr.dart';
import '../strings.dart';
import 'battle_screen.dart';
import 'theme.dart';

/// Story mode: playable Badr scenarios followed by clearly locked future campaigns.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  Future<void> _play(StoryChapter ch) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(deck: ch.playerDeck, mode: GameMode.story, chapter: ch),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _chapterCard(StoryChapter ch) {
    final done = Profile.storyDone.contains(ch.id);
    final reward = ch.rewardCard.isEmpty ? null : unitById[ch.rewardCard];
    return Card(
      color: Pal.parchment,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: done ? Pal.green : Pal.gold, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Pal.indigo,
                  child: Text('${ch.number}', style: const TextStyle(color: Pal.gold, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(ch.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                if (done) const Icon(Icons.check_circle, color: Pal.green),
              ],
            ),
            const SizedBox(height: 4),
            Text(ch.date, style: const TextStyle(color: Pal.bronze, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(tr('story_${ch.id}_desc')),
            const SizedBox(height: 8),
            Text(tr('story_objectives'), style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final o in ch.objectives) Text('• ${o.text}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              done
                  ? tr('story_replay_note')
                  : (ch.rewardCard.isEmpty
                      ? tr('story_reward_gold_only', {'gold': ch.rewardGold})
                      : tr('story_reward_note', {'gold': ch.rewardGold, 'card': reward?.name ?? '-'})),
              style: const TextStyle(fontSize: 12, color: Pal.bronze),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _play(ch),
                icon: const Icon(Icons.play_arrow),
                label: Text(done ? tr('story_replay') : tr('story_play')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lockedChapter(String titleKey, String descKey, int number, List<String> stages) => Card(
        color: const Color(0xFFE5DCC8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Pal.bronze.withAlpha(110)),
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Pal.indigo.withAlpha(210),
            child: const Icon(Icons.lock, color: Pal.gold),
          ),
          title: Text('${tr('story_chapter', {'n': number})} · ${tr(titleKey)}',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Pal.indigo)),
          subtitle: Text(tr(descKey)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            for (var i = 0; i < stages.length; i++)
              Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${i + 1}. ', style: const TextStyle(color: Pal.bronze, fontWeight: FontWeight.w900)),
                Expanded(child: Text(stages[i], style: const TextStyle(color: Pal.ink, height: 1.3))),
              ])),
            const SizedBox(height: 6),
            Align(alignment: Alignment.centerLeft, child: Text((currentLanguage == 'fr' ? 'CHAPITRE EN PRÉPARATION · DOSSIER HISTORIQUE' : 'CHAPTER IN PREPARATION · HISTORICAL OUTLINE'), style: TextStyle(color: Pal.bronze, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .7))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('story_title'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(tr('story_intro_note'), style: const TextStyle(color: Pal.bronze, fontSize: 12)),
                const SizedBox(height: 5),
                Text(currentLanguage == 'fr' ? 'Les chapitres verrouillés présentent leur trame historique prévue. Leurs batailles jouables seront ajoutées après vérification des événements et conception de leurs objectifs.' : 'Locked chapters show their planned historical outline. Playable battles will be added after event review and objective design.', style: const TextStyle(color: Pal.ink, fontSize: 12, height: 1.35)),
                const SizedBox(height: 8),
                for (final ch in storyChapters) _chapterCard(ch),
                const SizedBox(height: 8),
                Text(tr('story_future_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Pal.indigo)),
                const SizedBox(height: 4),
                _lockedChapter('story_trench_title', 'story_trench_desc', 4, (currentLanguage == 'fr' ? ['La coalition rassemble plusieurs groupes contre Médine.', 'La consultation et la décision de creuser un fossé sur le front exposé.', 'Les semaines de siège : défense, ravitaillement, fatigue et tensions.', 'La crise de la coalition et la levée du siège.'] : ['The coalition gathers several groups against Madinah.', 'Consultation and the decision to dig a trench along the exposed front.', 'Weeks of siege: defence, supplies, fatigue and tension.', 'The coalition crisis and the lifting of the siege.'])),
                _lockedChapter('story_khaybar_title', 'story_khaybar_desc', 5, (currentLanguage == 'fr' ? ['Contexte politique et départ vers l’oasis fortifiée.', 'Progression entre les positions fortifiées et les palmeraies.', 'Sièges successifs, négociations et conditions de reddition.', 'Conséquences de la campagne et organisation de l’oasis.'] : ['Political context and departure toward the fortified oasis.', 'Advance among fortified positions and palm groves.', 'Successive sieges, negotiations and terms of surrender.', 'The campaign’s consequences and the oasis’s administration.'])),
                _lockedChapter('story_mecca_title', 'story_mecca_desc', 6, (currentLanguage == 'fr' ? ['La rupture du pacte de Hudaybiyya et les préparatifs.', 'La marche vers La Mecque et les dispositions pour limiter les affrontements.', 'L’entrée dans la ville et les décisions prises après la victoire.', 'La réconciliation, l’amnistie rapportée par les sources et les conséquences.'] : ['The breach of the Hudaybiyya pact and the preparations.', 'The march toward Mecca and measures intended to limit fighting.', 'Entry into the city and decisions taken after the victory.', 'Reconciliation, the amnesty reported in sources, and the aftermath.'])),
                _lockedChapter('story_yarmouk_title', 'story_yarmouk_desc', 7, (currentLanguage == 'fr' ? ['Le contexte des campagnes byzantines et musulmanes en Syrie.', 'Le rassemblement des armées et la lecture du terrain.', 'Les journées de combat, les manœuvres et les enjeux de commandement.', 'L’issue de la bataille et ses conséquences régionales.'] : ['The context of Byzantine and Muslim campaigns in Syria.', 'The armies assemble and assess the terrain.', 'Days of fighting, manoeuvres and command decisions.', 'The battle’s outcome and regional consequences.'])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
