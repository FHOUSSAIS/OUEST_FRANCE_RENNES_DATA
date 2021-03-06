SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ADRESSE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_adr_systeme : Système
--			  @v_adr_base : Base
--			  @v_adr_sousbase : Sous-base
--			  @v_tra_id : Identifiant traduction
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des adresse
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ADRESSE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_adr_systeme bigint,
	@v_adr_base bigint,
	@v_adr_sousbase bigint,
	@v_tra_id int,
	@v_lan_id varchar(3),
	@v_lib_libelle varchar(8000),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error smallint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ADRESSE, LIBELLE WHERE LIB_TRADUCTION = ADR_IDTRADUCTION AND LIB_LIBELLE = @v_lib_libelle)
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
				SELECT @v_error = @@ERROR
				IF @v_error = 0
					SELECT @v_retour = 0
			END
			ELSE
				SELECT @v_retour = 117
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM CHARGE WHERE CHG_ADR_KEYSYS = @v_adr_systeme AND CHG_ADR_KEYBASE = @v_adr_base
				AND CHG_ADR_KEYSSBASE = @v_adr_sousbase)
			UNION (SELECT 1 FROM TACHE WHERE TAC_IDADRSYS = @v_adr_systeme AND TAC_IDADRBASE = @v_adr_base
				AND TAC_IDADRSSBASE = @v_adr_sousbase)
			UNION (SELECT 1 FROM EVT_ENERGIE_EN_COURS WHERE EEC_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base
				AND COE_ADRSSBASE = @v_adr_sousbase)))
		BEGIN
			DELETE CONFIG_RSV_ENERGIE WHERE CRE_IDOBJ IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base AND COE_ADRSSBASE = @v_adr_sousbase)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE IN (SELECT COE_ID FROM CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base AND COE_ADRSSBASE = @v_adr_sousbase)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE CONFIG_OBJ_ENERGIE WHERE COE_ADRSYS = @v_adr_systeme AND COE_ADRBASE = @v_adr_base AND COE_ADRSSBASE = @v_adr_sousbase
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE STRUCTURE WHERE STR_SYSTEME = @v_adr_systeme AND STR_BASE = @v_adr_base AND STR_SOUSBASE = @v_adr_sousbase
						SELECT @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE ADRESSE WHERE ADR_SYSTEME = @v_adr_systeme AND ADR_BASE = @v_adr_base AND ADR_SOUSBASE = @v_adr_sousbase
							SELECT @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
								IF @v_error = 0
									SELECT @v_retour = 0
							END
						END
					END
				END
			END
		END
		ELSE
			SELECT @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

