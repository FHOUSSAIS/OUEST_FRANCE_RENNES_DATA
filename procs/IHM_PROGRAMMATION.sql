SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: IHM_PROGRAMMATION
-- Paramètre d'entrée	: @v_action : Action à mener
--			  @v_ssaction : Sous action à mener
--			  @v_evc_id : Identifiant
--			  @v_evc_jour : Jour
--			  @v_evc_date : Date
--			  @v_evc_heure : Heure
--			  @v_evc_typeact : Type
--			  @v_evc_agv : Identifiant AGV
--			  @v_evc_actif : Actif
--			  @v_minute : Nombre de minutes
--			  @v_agv_origine : Identifiant AGV origine copier/coller
--			  @v_agv_destination : Identifiant AGV destination copier/coller
--			  @v_jour_origine : Jour origine copier/coller
--			  @v_jour_destination : Jour destination copier/coller
--			  @v_date_origine : Date origine copier/coller
--			  @v_date_destination : Date destination copier/coller
-- Paramètre de sortie	: @v_retour : Code de retour
-- Descriptif		: Gestion de la programmation de la gestion d'énergie
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[IHM_PROGRAMMATION]
	@v_action smallint,
	@v_ssaction smallint,
	@v_evc_id int,
	@v_evc_jour tinyint,
	@v_evc_date datetime,
	@v_evc_heure datetime,
	@v_evc_typeact tinyint,
	@v_evc_agv tinyint,
	@v_evc_actif bit,
	@v_minute smallint,
	@v_agv_origine tinyint,
	@v_agv_destination tinyint,
	@v_jour_origine int,
	@v_jour_destination int,
	@v_date_origine datetime,
	@v_date_destination datetime,
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
	SET @v_retour = 113
	SET @v_error = 0
	IF @v_action = 0
	BEGIN
		INSERT INTO CONFIG_EVT_ENERGIE (EVC_JOUR, EVC_DATE, EVC_HEURE, EVC_TYPEACT, EVC_AGV, EVC_ACTIF)
			VALUES (@v_evc_jour, @v_evc_date, @v_evc_heure, @v_evc_typeact, @v_evc_agv, 1)
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	ELSE IF @v_action = 1
	BEGIN
		IF @v_ssaction = 0
		BEGIN
			UPDATE CONFIG_EVT_ENERGIE SET EVC_ACTIF = @v_evc_actif WHERE EVC_AGV = @v_evc_agv
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE IF @v_ssaction = 1
		BEGIN
			UPDATE CONFIG_EVT_ENERGIE SET EVC_HEURE = @v_evc_heure, EVC_TYPEACT = @v_evc_typeact
				WHERE EVC_ID = @v_evc_id
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE  IF @v_ssaction = 2
		BEGIN
			UPDATE CONFIG_EVT_ENERGIE SET EVC_JOUR = CASE WHEN DAY(DATEADD(minute, @v_minute, EVC_HEURE)) <> DAY(EVC_HEURE) THEN CASE EVC_JOUR + SIGN(@v_minute) WHEN 0 THEN 7 WHEN 8 THEN 1 ELSE EVC_JOUR + SIGN(@v_minute) END ELSE EVC_JOUR END,
				EVC_HEURE = CASE WHEN DAY(DATEADD(minute, @v_minute, EVC_HEURE)) <> DAY(EVC_HEURE) THEN DATEADD(day, -SIGN(@v_minute), DATEADD(minute, @v_minute, EVC_HEURE)) ELSE DATEADD(minute, @v_minute, EVC_HEURE) END
				WHERE EVC_AGV = @v_evc_agv AND EVC_JOUR IS NOT NULL
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE  IF @v_ssaction = 3
		BEGIN
			UPDATE CONFIG_EVT_ENERGIE SET EVC_DATE = CASE WHEN DAY(DATEADD(minute, @v_minute, EVC_HEURE)) <> DAY(EVC_HEURE) THEN DATEADD(day, SIGN(@v_minute), EVC_DATE) ELSE EVC_DATE END,
				EVC_HEURE = CASE WHEN DAY(DATEADD(minute, @v_minute, EVC_HEURE)) <> DAY(EVC_HEURE) THEN DATEADD(day, -SIGN(@v_minute), DATEADD(minute, @v_minute, EVC_HEURE)) ELSE DATEADD(minute, @v_minute, EVC_HEURE) END
				WHERE EVC_AGV = @v_evc_agv AND EVC_DATE IS NOT NULL
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = 0
		END
		ELSE  IF @v_ssaction = 4
		BEGIN
			DELETE CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_agv_destination AND EVC_JOUR = @v_jour_destination
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				INSERT INTO CONFIG_EVT_ENERGIE (EVC_JOUR, EVC_DATE, EVC_HEURE, EVC_TYPEACT, EVC_AGV, EVC_ACTIF)
					SELECT @v_jour_destination, NULL, EVC_HEURE, EVC_TYPEACT, @v_agv_destination, 1
					FROM CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_agv_origine AND EVC_JOUR = @v_jour_origine
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
		ELSE  IF @v_ssaction = 5
		BEGIN
			DELETE CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_agv_destination AND EVC_DATE = @v_date_destination
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				INSERT INTO CONFIG_EVT_ENERGIE (EVC_JOUR, EVC_DATE, EVC_HEURE, EVC_TYPEACT, EVC_AGV, EVC_ACTIF) 
					SELECT NULL, @v_date_destination, EVC_HEURE, EVC_TYPEACT, @v_agv_destination, 1
					FROM CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_agv_origine AND EVC_DATE = @v_date_origine
				SET @v_error = @@ERROR
				IF @v_error = 0
					SET @v_retour = 0
			END
		END
	END
	ELSE IF @v_action = 2
	BEGIN
		DELETE CONFIG_EVT_ENERGIE WHERE EVC_ID = @v_evc_id
		SET @v_error = @@ERROR
		IF @v_error = 0
			SET @v_retour = 0
	END
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

