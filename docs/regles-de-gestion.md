# Règles de gestion de PullBar

Ce fork répond à une question : **« Ai-je une action à faire sur une PR ? »**
Il distingue les reviews qui me sont demandées des actions sur mes propres PR.
Les informations correspondent au dernier rafraîchissement ; PullBar ne merge
aucune PR automatiquement.

## Les trois sections

| Section | Contenu |
| --- | --- |
| **To review** | PR ouvertes dont la review m’est demandée, en excluant mes propres PR. |
| **My PRs** | Mes PR ouvertes. |
| **Just so you know · develop** | Les 3 ou 5 dernières PR mergées vers `develop`, tous dépôts configurés confondus, triées par date de merge. Cette section ne contribue pas aux compteurs. |

Les PR ouvertes sont triées par date de création, de la plus ancienne en haut à
la plus récente en bas, dans « To review », « My PRs » et les catégories
personnalisées. Les actions à traiter ne modifient pas cet ordre.

Les lignes montrent notamment le titre, le dépôt sans l’organisation, l’auteur,
les approvals, l’état de la CI et les discussions. Le calendrier indique le temps
depuis la création, ou depuis le merge dans « Just so you know ». Les nombres de
lignes ajoutées/supprimées sont masqués. Cliquer ouvre la PR ; Option-clic copie son URL.

## Les indicateurs dans la barre macOS

| Indicateur | Signification |
| --- | --- |
| **Badge rouge** | Nombre de PR qui demandent ma review. |
| **Bonhomme + nombre** | Nombre de mes PR qui demandent au moins une action. Une PR compte une seule fois, même si plusieurs actions sont nécessaires. |
| **Bonhomme plein vert** | Au moins une de mes PR satisfait les conditions « Ready to merge » ci-dessous. |
| **Chargement** | Un indicateur remplace les compteurs pendant le rafraîchissement. |

Les compteurs à zéro sont masqués. Le bonhomme disparaît si aucune de mes PR
n’a d’action à traiter. Son survol explique les compteurs.

## Qu’est-ce qui compte comme une action sur mes PR ?

- Une CI en échec.
- Une review qui demande des changements.
- Une conversation de review non résolue où je ne suis pas en attente d’une réponse.
- De nouveaux commentaires de review détectés comme non lus.
- Un conflit de merge.
- Une PR prête à être mergée.

Une CI simplement en cours, une approval manquante ou une PR en draft ne sont
pas, à eux seuls, des actions dans ce compteur.

## Conversations : à moi de répondre ou en attente ?

Quand mon commentaire publié est le dernier d’une conversation ouverte,
PullBar considère que j’attends une réponse. Cette conversation ne contribue
plus au compteur d’actions, mais reste affichée :

- `1 unresolved discussion · Awaiting reply` : toutes les conversations ouvertes connues sont en attente.
- `3 unresolved discussions · Awaiting reply in 2` : deux conversations attendent une réponse ; la troisième reste une action.

Une réponse ultérieure de quelqu’un d’autre rend la conversation à nouveau
actionnable. Une réponse encore en brouillon ne suffit pas. Si l’historique des
commentaires est incomplet ou si les dates ne permettent pas de trancher,
PullBar ne classe pas la conversation comme étant en attente.

Le signal orange **« quelqu’un a répondu après toi »** compte les conversations
ouvertes où quelqu’un a publié après mon dernier commentaire. Il disparaît quand
je réponds à nouveau ou que la conversation est résolue, pas quand je lis la PR.
Il concerne les conversations de review sur le code, pas les commentaires généraux.

**« Awaiting reply » est une déduction, pas un statut GitHub.** Une autre action
sur la même PR peut maintenir le bonhomme : CI en échec, changements demandés,
commentaires de review non lus, conflit… Une conversation en attente reste non
résolue et continue à empêcher l’indication « Ready to merge ».

## Quand une PR est-elle « Ready to merge » ?

Toutes les conditions suivantes doivent être réunies :

- La PR n’est pas en draft.
- Au moins **2 reviewers distincts** ont une approval courante.
- La CI est réussie : au moins un check a réussi, les autres sont terminés avec un résultat accepté (`SUCCESS`, `NEUTRAL` ou `SKIPPED`).
- Aucune demande de changements ni conversation non résolue.
- GitHub indique `MERGEABLE` et `CLEAN`, avec une décision de review absente ou `APPROVED`.
- Les détails nécessaires des reviews, conversations et checks sont disponibles.

Mes PR prêtes à merger ont également un check vert sur leur ligne. Cette
indication n’est pas une garantie de disposer de toutes les permissions de merge.
**Le seuil de 2 approvals et la branche `develop` sont actuellement fixes.**

## CI et informations non lues

La CI distingue les checks en cours, en file d’attente, en échec, réussis ou
inconnus. Une erreur reste visible même si d’autres checks tournent encore.
La durée est affichée si une date de début est disponible ; avec plusieurs
checks en cours, c’est la durée la plus longue connue. Une CI absente, incomplète
ou composée uniquement de checks ignorés/neutres ne signifie pas « tests OK ».
PullBar affiche les checks GitHub sans pouvoir vérifier qu’ils exécutent réellement des tests.

Le **point bleu** signifie que GitHub considère la PR comme non lue. C’est un
état global de la PR, pas un nombre de commentaires non lus. Pour le signal
« New review comments », PullBar combine cet état avec les reviews publiées et
la date locale de dernière ouverture depuis PullBar. Ouvrir une PR depuis
PullBar acquitte localement les commentaires déjà présents ; cela ne résout
ni les conversations ni les demandes de changements.

## Réglages disponibles

| Réglage | Effet |
| --- | --- |
| **Action dashboard** | Activé par défaut. Le désactiver réactive les catégories personnalisées et leur compteur ; les catégories enregistrées sont conservées. |
| **Show draft PRs** | Activé par défaut. Les drafts portent 🚧 ; désactiver l’option les retire des listes et des compteurs. Un draft peut avoir des actions, mais jamais être « Ready to merge ». |
| **Excluded repositories** | Un `organisation/repo` par ligne, sans distinction de casse. Retire leurs PR de toutes les sections et des compteurs, même si le dépôt est configuré dans les merges récents. |
| **Recent merges** | Active/désactive « Just so you know », choisit les dépôts et le nombre total de résultats : 3 ou 5. |
| **Show Avatar / Show Labels** | Affiche ou masque les avatars et labels. |
| **Show debug information** | Affiche les données techniques de CI pour le diagnostic ; désactivé par défaut. |
| **Refresh Rate / Launch at login** | Règle la fréquence de rafraîchissement et le lancement à l’ouverture de session. |

Les modifications des réglages sont appliquées à la fermeture de la fenêtre.
Le bouton **Refresh** conserve le menu ouvert et met son contenu à jour une fois
les données reçues.

## Données incomplètes et erreurs

Une erreur de chargement des PR conserve la liste précédente avec un avertissement
et remplace les compteurs par `!`. Une erreur des merges récents est signalée dans
leur section et n’altère pas les compteurs d’actions.

Les recherches sont paginées ; dépasser la limite de 1 000 résultats est signalé.
Les détails de reviews, conversations et checks sont limités à 100 éléments par
collection. Le suivi des réponses inspecte les 100 derniers commentaires de
chaque conversation récupérée. Les informations incomplètes sont signalées ; le
nombre de conversations avec une réponse peut alors être indiqué comme un minimum.

[Retour au README](../README.md)
