; loads the deck id in a from DeckPointers and copies it to wPlayerDeck or to
; wOpponentDeck, depending on whose turn it is.
; sets carry flag if an invalid deck id is used.
LoadDeck::
	push hl
	ld l, a
	ld h, $0
	ldh a, [hBankROM]
	push af
	ld a, BANK(DeckPointers)
	call BankswitchROM
	add hl, hl
	ld de, DeckPointers
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, d
	or e
	jr z, .null_pointer
	call CopyDeckData
	pop af
	call BankswitchROM
	pop hl
	or a
	ret
.null_pointer
	pop af
	call BankswitchROM
	pop hl
	scf
	ret

; input:
; - de = source deck in RAM (120 bytes)
; - hl = SRAM destination (90 bytes)
; Packs 60 12-bit card IDs into 90 bytes (2 cards per 3 bytes).
CompressDeckToSRAM::
	push hl
	push de
	push bc
	ld c, DECK_SIZE / 2 ; 30 pairs
.loop
	; Card 1: low byte in [de], high byte in [de+1]
	ld a, [de]
	inc de
	ld [hli], a ; Card 1 low byte
	ld a, [de]
	inc de
	swap a
	and $f0
	ld b, a ; b = Card 1 high nibble << 4

	; Card 2: low byte in [de], high byte in [de+1]
	ld a, [de]
	inc de
	ld [hli], a ; Card 2 low byte
	ld a, [de]
	inc de
	and $0f
	or b
	ld [hli], a ; combined high nibbles byte

	dec c
	jr nz, .loop

	pop bc
	pop de
	pop hl
	ret

; loads deck saved in SRAM from de to hl
; input:
; - de = compressed deck in SRAM (90 bytes)
; - hl = RAM destination (120 bytes)
; Unpacks 90 bytes into 60 12-bit card IDs (2 cards per 3 bytes).
DecompressSRAMDeck::
	push hl
	push de
	push bc
	ld c, DECK_SIZE / 2 ; 30 pairs
.loop
	; Read Card 1 low byte
	ld a, [de]
	inc de
	ld [hli], a ; write Card 1 low byte

	; Read Card 2 low byte
	ld a, [de]
	inc de
	push af ; save Card 2 low byte

	; Read combined high nibbles byte
	ld a, [de]
	inc de
	ld b, a ; b = combined high nibbles

	; Card 1 high nibble
	swap a
	and $0f
	ld [hli], a ; write Card 1 high byte

	; Card 2 low byte
	pop af
	ld [hli], a ; write Card 2 low byte

	; Card 2 high nibble
	ld a, b
	and $0f
	ld [hli], a ; write Card 2 high byte

	dec c
	jr nz, .loop

	pop bc
	pop de
	pop hl
	ret
