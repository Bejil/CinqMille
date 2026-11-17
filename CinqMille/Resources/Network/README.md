# Multijoueur réseau (Firebase)

## Configuration Firebase

1. Crée un projet sur [Firebase Console](https://console.firebase.google.com).
2. Ajoute une app iOS avec le bundle id `com.michaelblin.cinqmille`.
3. Télécharge `GoogleService-Info.plist` et place-le dans `CinqMille/` (même niveau que les sources synchronisées), **pas** le fichier `.example`.
4. Active **Anonymous Authentication**.
5. Crée une base **Cloud Firestore** et déploie les règles de `firestore.rules` (à affiner ensuite).
6. Crée un index composite si Firestore le demande pour la requête `code` (souvent pas nécessaire pour un simple `whereField("code")`).

Sans `GoogleService-Info.plist`, l’app démarre normalement mais le mode réseau affiche une erreur de configuration.

## Modèle Firestore

Collection `rooms` :

| Champ | Type | Description |
| --- | --- | --- |
| `code` | string | Code à 6 caractères |
| `hostId` | string | UID Firebase du créateur |
| `status` | string | `waiting` / `playing` / `finished` |
| `maxPlayers` | number | 2 à 4 |
| `players` | array | `{ id, name, isHost, joinedAt }` |
| `createdAt` / `updatedAt` | timestamp | |
| `game` | map | État synchronisé de la partie (dés, scores, tour…) |
| `rules` | map | Snapshot des règles de l'hôte au démarrage |

## Fonctionnalités

- Auth anonyme
- Créer une partie / rejoindre avec un code / lister les parties en attente
- Lobby temps réel (quitter / démarrer côté host dès 2 joueurs **tous prêts**)
- À l’arrivée : écran de règles simplifié + bouton « Je suis prêt » (`players[].isReady`)
- Règles de l’hôte figées dans `rooms.rules` et appliquées sur tous les clients
- État de partie synchronisé (`rooms.game`) : tours, dés, scores, victoire
- Limite de temps par tour (15 s, champ `game.turnEndsAt`, relancée à chaque relance mais pas au 1er lancer) : décompte sur Valider/Passer ; à 0 le tour est perdu sans points
- Nettoyage des parties inactives à l’ouverture du lobby :
  - `finished` : suppression immédiate
  - `waiting` sans activité depuis 30 min
  - `playing` sans activité depuis 10 min (`updatedAt` est rafraîchi à chaque action)
  - reprise de session : si l’app a crashé / été tuée, la dernière room mémorisée est quittée au prochain lancement du lobby

Le joueur dont c’est le tour pousse l’état après chaque action ; les autres écoutent le document.
