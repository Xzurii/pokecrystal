RunActivationAbilitiesInner:
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVar
	; do Trace first in case it traces an activation ability,
	; that way we can run one of the others after the trace.
	cp TRACE
	call z, TraceAbility
	; reload the ability byte if it changed
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVar
	cp TRACE
	jr nz, .continue
	ret ; the trace failed, so don't continue
.continue
	; Do Imposter second to allow Transformed abilities to activate
	cp IMPOSTER
	jp z, ImposterAbility
	cp DRIZZLE
	jp z, DrizzleAbility
	cp DROUGHT
	jp z, DroughtAbility
	cp SAND_STREAM
	jp z, SandStreamAbility
	cp CLOUD_NINE
	jp z, CloudNineAbility
	cp INTIMIDATE
	jp z, IntimidateAbility
	cp PRESSURE ; just prints a message
	jr nz, .skip_pressure
	ld hl, NotifyPressure
	call StdBattleTextBox
.skip_pressure
	cp DOWNLOAD
	jp z, DownloadAbility
	cp MOLD_BREAKER ; just prints a message
	jr nz, .skip_mold_breaker
	ld hl, NotifyMoldBreaker
	call StdBattleTextBox
.skip_mold_breaker
	cp ANTICIPATION
	jp z, AnticipationAbility
	cp FOREWARN
	jp z, ForewarnAbility
	cp FRISK
	jp z, FriskAbility
	cp UNNERVE ; just prints a message
	jr nz, .skip_unnerve
	ld hl, NotifyUnnerve
	call StdBattleTextBox
.skip_unnerve
	jp RunStatusHealAbilities

RunEnemyStatusHealAbilities:
	callba SwitchTurnCore
	call RunStatusHealAbilities
	callba SwitchTurnCore
	ret

RunStatusHealAbilities:
; Procs abilities that protect against statuses.
	; Needed because this is called elsewhere.
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVar
	cp LIMBER
	jp z, LimberAbility
	cp IMMUNITY
	jp z, ImmunityAbility
	cp MAGMA_ARMOR
	jp z, MagmaArmorAbility
	cp WATER_VEIL
	jp z, WaterVeilAbility
	cp INSOMNIA
	jp z, InsomniaAbility
	cp VITAL_SPIRIT
	jp z, VitalSpiritAbility
	cp OWN_TEMPO
	jp z, OwnTempoAbility
	cp OBLIVIOUS
	jp z, ObliviousAbility
	ret

ImmunityAbility:
	ld a, 1 << PSN
	jr HealStatusAbility
WaterVeilAbility:
	ld a, 1 << BRN
	jr HealStatusAbility
MagmaArmorAbility:
	ld a, 1 << FRZ
	jr HealStatusAbility
LimberAbility:
	ld a, 1 << PAR
	jr HealStatusAbility
InsomniaAbility:
VitalSpiritAbility:
	ld a, 1 << SLP
	jr HealStatusAbility
HealStatusAbility:
	ld b, a
	ld a, BATTLE_VARS_STATUS
	call GetBattleVar
	and b
	ret z ; not afflicted/wrong status
	call ShowAbilityActivation
	ld a, BATTLE_VARS_STATUS
	call GetBattleVarAddr
	xor a
	ld [hl], a
	ld hl, BecameHealthyText
	call StdBattleTextBox
	ld a, [hBattleTurn]
	and a
	jr z, .is_player
	callab CalcEnemyStats
	ret
.is_player
	callab CalcPlayerStats
	ret

OwnTempoAbility:
	ld a, BATTLE_VARS_SUBSTATUS3
	call GetBattleVar
	and SUBSTATUS_CONFUSED
	ret z ; not confused
	call ShowAbilityActivation
	ld a, BATTLE_VARS_SUBSTATUS3
	call GetBattleVarAddr
	res SUBSTATUS_CONFUSED, [hl]
	ld hl, ConfusedNoMoreText
	jp StdBattleTextBox

ObliviousAbility:
	ld a, BATTLE_VARS_SUBSTATUS1
	call GetBattleVar
	and SUBSTATUS_IN_LOVE
	ret z ; not infatuated
	call ShowAbilityActivation
	ld a, BATTLE_VARS_SUBSTATUS1
	call GetBattleVarAddr
	res SUBSTATUS_IN_LOVE, [hl]
	ld hl, ConfusedNoMoreText
	jp StdBattleTextBox

TraceAbility:
	ld a, BATTLE_VARS_ABILITY_OPP
	call GetBattleVar
	cp TRACE
	jr z, .trace_failure
	cp IMPOSTER
	jr z, .trace_failure
	push af
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVarAddr
	pop af
	ld [hl], a
	ld hl, TraceActivationText
	call StdBattleTextBox
	; handle swift swim, etc.
	ld a, [hBattleTurn]
	jr z, .is_player
	callab CalcEnemyStats
	ret
.is_player
	callab CalcPlayerStats
	ret
.trace_failure
	ld hl, TraceFailureText
	call StdBattleTextBox
	ret

; Lasts 5 turns consistent with Generation VI.
DrizzleAbility:
	ld a, WEATHER_RAIN
	jr WeatherAbility
DroughtAbility:
	ld a, WEATHER_SUN
	jr WeatherAbility
SandStreamAbility:
	ld a, WEATHER_SANDSTORM
	jr WeatherAbility
CloudNineAbility:
	ld a, WEATHER_NONE
	jr WeatherAbility
WeatherAbility:
	ld b, a
	ld a, [Weather]
	cp b
	ret z ; don't re-activate it
	call ShowAbilityActivation
	ld a, 5
	ld [WeatherCount], a
	ld a, b
	ld [Weather], a
	; handle swift swim, etc.
	push bc
	callab CalcPlayerStats
	callab CalcEnemyStats
	pop bc
	ld a, b
	cp WEATHER_RAIN
	jr z, .handlerain
	cp WEATHER_SUN
	jr z, .handlesun
	cp WEATHER_SANDSTORM
	jr z, .handlesandstorm
	; we're dealing with cloud nine
	xor a
	ld [WeatherCount], a
	ld hl, BattleText_TheWeatherSubsided
	jp StdBattleTextBox
.handlerain
	ld de, RAIN_DANCE
	callab Call_PlayBattleAnim
	ld hl, DownpourText
	jp StdBattleTextBox
.handlesun
	ld de, SUNNY_DAY
	callab Call_PlayBattleAnim
	ld hl, SunGotBrightText
	jp StdBattleTextBox
.handlesandstorm
	ld de, SANDSTORM
	callab Call_PlayBattleAnim
	ld hl, SandstormBrewedText
	jp StdBattleTextBox

IntimidateAbility:
	call ShowAbilityActivation
	callba DisableAnimations
	callba ResetMiss
	callba BattleCommand_AttackDown
	callba BattleCommand_StatDownMessage
	ret

DownloadAbility:
; Increase Atk if enemy Def is lower than SpDef, otherwise SpAtk
	call ShowAbilityActivation
	callba DisableAnimations
	ld hl, EnemyMonDefense
	ld a, [hBattleTurn]
	and a
	jr z, .ok
	ld hl, BattleMonDefense
.ok
	ld a, [hli]
	ld b, a
	ld a, [hl]
	ld c, a
	ld hl, EnemyMonSpclDef + 1
	ld a, [hBattleTurn]
	and a
	jr z, .ok2
	ld hl, BattleMonSpclDef + 1
.ok2
	ld a, [hld]
	ld e, a
	ld a, [hl]
	cp b
	jr c, .inc_spatk
	jr nz, .inc_atk
	; The high defense bits are equal, so compare the lower bits
	ld a, c
	cp e
	jr c, .inc_atk
.inc_spatk
	callba ResetMiss
	callba BattleCommand_SpecialAttackUp
	callba BattleCommand_StatUpMessage
	ret
.inc_atk
	callba ResetMiss
	callba BattleCommand_AttackUp
	callba BattleCommand_StatUpMessage
	ret

ImposterAbility:
	call ShowAbilityActivation
	callba DisableAnimations
	callba ResetMiss
	callba BattleCommand_Transform
	ld de, TRANSFORM
	callab Call_PlayBattleAnim
	ret

AnticipationAbility:
ForewarnAbility:
FriskAbility:
	ret

RunEnemyOwnTempoAbility:
	callba BattleCommand_SwitchTurn
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVar
	cp OWN_TEMPO
	call z, SynchronizeAbility
	callba BattleCommand_SwitchTurn
	ret

RunEnemySynchronizeAbility:
	callba BattleCommand_SwitchTurn
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVar
	cp SYNCHRONIZE
	call z, SynchronizeAbility
	callba BattleCommand_SwitchTurn
	ret

SynchronizeAbility:
	ld a, BATTLE_VARS_STATUS
	call GetBattleVar
	and ALL_STATUS
	ret z ; not statused
	call ShowAbilityActivation
	callba ResetMiss
	callba DisableAnimations
	ld a, BATTLE_VARS_STATUS
	call GetBattleVar
	cp 1 << PSN
	jr z, .is_psn
	cp 1 << BRN
	jr z, .is_brn
	callba BattleCommand_Paralyze
	ret
.is_psn
	callba BattleCommand_Poison
	ret
.is_brn
	callba BattleCommand_Burn
	ret

RunEnemyStatIncreaseAbilities:
	callba BattleCommand_SwitchTurn
	ld a, BATTLE_VARS_ABILITY
	call GetBattleVar
	cp DEFIANT
	call z, DefiantAbility
	cp COMPETITIVE
	call z, CompetitiveAbility
	callba BattleCommand_SwitchTurn
	ret

DefiantAbility:
	ld a, ATTACK
	jr StatIncreaseAbility
CompetitiveAbility:
	ld a, SP_ATTACK
StatIncreaseAbility:
	ld b, a
	call ShowAbilityActivation
	callba DisableAnimations
	callba ResetMiss
	ld a, b
	cp ATTACK
	jr nz, .sp_atk
	callba BattleCommand_AttackUp2
	callba BattleCommand_StatUpMessage
	ret
.sp_atk
	callba BattleCommand_SpecialAttackUp2
	callba BattleCommand_StatUpMessage
	ret

ShowAbilityActivation::
	xor a
	jr ShowAbilityActivationInner
ShowEnemyAbilityActivation::
	ld a, 1
ShowAbilityActivationInner:
; a=0: show player's ability, a=1: opponent's
	push bc
	and a
	jr nz, .enemy_activation
	ld hl, AbilityActivationText
	call StdBattleTextBox
	pop bc
	ret

.enemy_activation
	ld hl, EnemyAbilityActivationText
	call StdBattleTextBox
	pop bc
	ret