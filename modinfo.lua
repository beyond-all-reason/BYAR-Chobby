return {
  name = 'BYAR Chobby',
  shortName = 'BYAR_CHOBBY',
  description = 'BYAR mutator for Chobby',
  version = '$VERSION',
  mutator = 'Official',
  modtype = 5,
  onlyLocal = true,
  depend = {
      -- For developing base chobby, switch out dependency
      --'rapid://chobby:test', --this uses rapid pinned chobby
      --'Chobby $VERSION', -- this specifies chobby.sdd working path
  },

}
