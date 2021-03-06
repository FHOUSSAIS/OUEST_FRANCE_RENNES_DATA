SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: CFG_ZONE
-- Paramètre d'entrées	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_zne_id : Identifiant
--			  @v_zne_cap_min : Capacité minimale
--			  @v_zne_cap_max : Capacité maximale
--			  @v_zne_booking : Booking
--			  @v_zne_type : Type
--			  @v_jez_idjeu : Identifiant jeu de zones
--			  @v_bas_base : Base
--			  @v_lan_id : Identifiant langue
--			  @v_lib_libelle : Libellé
-- Paramètre de sorties	: @v_retour : Code de retour
--			  @v_tra_id : Identifiant traduction
-- Descriptif		: Gestion des zones
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_ZONE]
	@v_action smallint,
	@v_ssaction smallint,
	@v_zne_id int,
	@v_zne_cap_min tinyint,
	@v_zne_cap_max tinyint,
	@v_zne_booking bit,
	@v_zne_type bit,
	@v_jez_idjeu int,
	@v_bas_base bigint,
	@v_tra_id int out,
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
	@v_error int,
	@v_bas_systeme bigint

	BEGIN TRAN
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ZONE INNER JOIN LIBELLE ON LIB_TRADUCTION = ZNE_IDTRADUCTION WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_lib_libelle)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM JEU_ZONE)
			BEGIN
				SELECT @v_tra_id = CASE SIGN(MIN(TRA_ID)) WHEN -1 THEN MIN(TRA_ID) - 1 ELSE -1 END FROM TRADUCTION
				INSERT INTO TRADUCTION (TRA_ID, TRA_SYSTEME) VALUES (@v_tra_id, 0)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					INSERT INTO LIBELLE (LIB_TRADUCTION, LIB_LANGUE, LIB_LIBELLE)
						SELECT @v_tra_id, LIB_LANGUE, LIB_LIBELLE FROM LIBELLE WHERE LIB_TRADUCTION = 1974
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO JEU_ZONE (JEZ_IDJEU, JEZ_IDTRADUCTION) VALUES (-1, 1974)
						SET @v_error = @@ERROR
					END
				END
			END
			IF @v_error = 0
			BEGIN
				EXEC @v_error = LIB_TRADUCTION @v_action, @v_lan_id, @v_lib_libelle, @v_tra_id out
				IF @v_error = 0
				BEGIN
					INSERT INTO ZONE (ZNE_ID, ZNE_CAP_MIN, ZNE_CAP_MAX, ZNE_BOOKING, ZNE_OCCCRT, ZNE_IDTRADUCTION, ZNE_TYPE)
						VALUES (@v_zne_id, 0, 255, 0, 0, @v_tra_id, @v_zne_type)
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO ASSOCIATION_ZONE_JEU_ZONE (AZJ_JEU_ZONE, AZJ_ZONE, AZJ_CAP_MIN, AZJ_CAP_MAX, AZJ_BOOKING) SELECT JEZ_IDJEU, ZNE_ID, ZNE_CAP_MIN, ZNE_CAP_MAX, ZNE_BOOKING FROM ZONE, JEU_ZONE WHERE ZNE_ID = @v_zne_id
						SET @v_error = @@ERROR
						IF @v_error = 0
							SET @v_retour = 0
					END
				END
			END
		END
		ELSE
			SET @v_retour = 117
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM ZONE INNER JOIN LIBELLE ON LIB_TRADUCTION = ZNE_IDTRADUCTION WHERE LIB_LANGUE = @v_lan_id AND LIB_LIBELLE = @v_lib_libelle)
			BEGIN
				UPDATE LIBELLE SET LIB_LIBELLE = @v_lib_libelle WHERE LIB_LANGUE = @v_lan_id AND LIB_TRADUCTION = @v_tra_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
			ELSE
				SET @v_retour = 117
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE ZONE SET ZNE_TYPE = @v_zne_type WHERE ZNE_ID = @v_zne_id
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 2
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM JEU_ZONE HAVING COUNT(*) > 1)
			BEGIN
				UPDATE ZONE SET ZNE_CAP_MIN = @v_zne_cap_min, ZNE_CAP_MAX = @v_zne_cap_max, ZNE_BOOKING = @v_zne_booking WHERE ZNE_ID = @v_zne_id
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				UPDATE ASSOCIATION_ZONE_JEU_ZONE SET AZJ_CAP_MIN = @v_zne_cap_min, AZJ_CAP_MAX = @v_zne_cap_max, AZJ_BOOKING = @v_zne_booking WHERE AZJ_JEU_ZONE = @v_jez_idjeu AND AZJ_ZONE = @v_zne_id
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE IF @v_ssaction = 3
		BEGIN
			SELECT TOP 1 @v_bas_systeme = SYS_SYSTEME FROM SYSTEME
			IF NOT EXISTS (SELECT 1 FROM ZONE_CONTENU WHERE CZO_ZONE = @v_zne_id AND CZO_ADR_KEY_SYS = @v_bas_systeme AND CZO_ADR_KEY_BASE = @v_bas_base)
				AND EXISTS (SELECT 1 FROM BASE WHERE BAS_SYSTEME = @v_bas_systeme AND BAS_BASE = @v_bas_base)
			BEGIN
				INSERT INTO ZONE_CONTENU (CZO_ZONE, CZO_ADR_KEY_SYS, CZO_ADR_KEY_BASE) VALUES (@v_zne_id, @v_bas_systeme, @v_bas_base)
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 4
		BEGIN
			SELECT TOP 1 @v_bas_systeme = SYS_SYSTEME FROM SYSTEME
			IF EXISTS (SELECT 1 FROM ZONE_CONTENU WHERE CZO_ZONE = @v_zne_id AND CZO_ADR_KEY_SYS = @v_bas_systeme AND CZO_ADR_KEY_BASE = @v_bas_base)
			BEGIN
				DELETE ZONE_CONTENU WHERE CZO_ZONE = @v_zne_id AND CZO_ADR_KEY_SYS = @v_bas_systeme AND CZO_ADR_KEY_BASE = @v_bas_base
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
				SET @v_retour = 0
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		IF NOT EXISTS ((SELECT 1 FROM CONDITION WHERE CDT_VALEUR = @v_zne_id AND CDT_IDTRADUCTIONTEXTE = @v_tra_id)
			UNION (SELECT 1 FROM ACTION_REGLE WHERE ARE_PARAMS = @v_zne_id AND ARE_IDTRADUCTIONTEXTE = @v_tra_id)
			UNION (SELECT 1 FROM VARIABLE WHERE VAR_PARAMETRE = @v_zne_id AND VAR_TRADUCTIONTEXTE = @v_tra_id))
		BEGIN
			DELETE ASSOCIATION_ZONE_JEU_ZONE WHERE AZJ_ZONE = @v_zne_id
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				DELETE CRITERE_ZONE WHERE CRZ_IDZONE = @v_zne_id
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE OCCUPATION_ZONE WHERE OZO_IDZONE = @v_zne_id
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						DELETE ZONE_CONTENU WHERE CZO_ZONE = @v_zne_id
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE ZONE WHERE ZNE_ID = @v_zne_id
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								EXEC @v_error = LIB_TRADUCTION @v_action, NULL, NULL, @v_tra_id out
								IF @v_error = 0
									SET @v_retour = 0
							END
						END
					END
				END
			END
		END
		ELSE
			SET @v_retour = 114
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

