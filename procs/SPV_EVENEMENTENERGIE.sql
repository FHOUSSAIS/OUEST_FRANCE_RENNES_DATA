SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_EVENEMENTENERGIE
-- Paramètre d'entrée	: @v_type : Type
--						    0 : OperatingScreens
--							1 : AGV
--						  @v_iag_idagv : Identifiant AGV
--						  @v_mis_idmission : Identifiant mission
--						  @v_det_iddescription : Cause de la fin de la mission
--						  @v_lan_id varchar(3) : Langue
-- Paramètres de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--						  @v_dsp_iddefaut : Identifiant défaut SPV
--						  @v_dsp_information : Information défaut SPV
-- Descriptif		: Gestion des événement d'une mission
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_EVENEMENTENERGIE]
	@v_type bit,
	@v_iag_idagv tinyint,
	@v_mis_idmission int,
	@v_det_iddescription tinyint,
	@v_lan_id varchar(3) = NULL,
	@v_dsp_iddefaut int = 0 out,
	@v_dsp_information varchar(8000) out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_bat_id tinyint,
	@v_adr_idsysteme bigint,
	@v_adr_idbase bigint,
	@v_adr_idsousbase bigint,
	@v_tac_idtache int,
	@v_tac_idordre int,
	@v_eec_idevenement int,
	@v_eec_idplanification int,
	@v_par_cycle varchar(128),
	@v_par_intervalle varchar(128),
	@v_evc_datetime1 datetime,
	@v_evc_datetime2 varchar(5)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_ANNULATION tinyint,
	@DESC_EXECUTION_AUTOMATIQUE tinyint,
	@DESC_EXECUTION_MANUELLE tinyint	

-- Déclaration des constantes d'état d'événement d'énergie
DECLARE
	@ETAT_EVT_ENATTENTE tinyint,
	@ETAT_EVT_ENCOURS tinyint,
	@ETAT_EVT_TERMINE tinyint

-- Déclaration des constantes de types d'événements
DECLARE
	@TYPE_CHANGEMENT_BATTERIE tinyint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_BATTERIE tinyint

-- Déclaration des constantes de type d'objet énergie
DECLARE
	@TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME int

-- Déclaration des constantes de défaut
DECLARE
	@DEFA_UNCHARGED_BATTERY tinyint,
	@DEFA_UNPLANNED_CHANGE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_STOPPE = 3
	SET @ETAT_SUSPENDU = 4
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_ANNULATION = 9
	SET @ETAT_EVT_ENATTENTE = 1
	SET @ETAT_EVT_ENCOURS = 2
	SET @ETAT_EVT_TERMINE = 3
	SET @TYPE_CHANGEMENT_BATTERIE = 1
	SET @TYPE_BATTERIE = 2
	SET @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME = 3
	SET @DESC_EXECUTION_AUTOMATIQUE = 3
	SET @DESC_EXECUTION_MANUELLE = 4
	SET @DEFA_UNCHARGED_BATTERY = 1
	SET @DEFA_UNPLANNED_CHANGE = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO
	
	BEGIN TRAN
	SELECT @v_eec_idevenement = EEC_ID, @v_eec_idplanification = EEC_IDEVT FROM EVT_ENERGIE_EN_COURS
		WHERE EEC_IDMISSION = @v_mis_idmission AND EEC_ETAT = @ETAT_EVT_ENCOURS
	IF ((@v_eec_idevenement IS NOT NULL AND @v_eec_idplanification IS NULL AND @v_det_iddescription IN (@DESC_EXECUTION_AUTOMATIQUE, @DESC_EXECUTION_MANUELLE))
		OR (@v_mis_idmission IS NULL))
		AND EXISTS (SELECT 1 FROM CONFIG_RSV_ENERGIE INNER JOIN CONFIG_OBJ_ENERGIE ON COE_ID = CRE_IDOBJ WHERE CRE_IDAGV = @v_iag_idagv AND COE_TYPE = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME)
		AND NOT EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_DECHARGE = 1)
	BEGIN
		-- Récupération des paramètres indiquant l'intervalle minimum entre deux changements de batterie
		--   et le cycle horaire de changement de batterie
		SET @v_par_cycle = '480'
		SELECT @v_par_cycle = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'CYC_CHG_BATTERIE'
		SET @v_par_intervalle = '120'
		SELECT @v_par_intervalle = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'INT_CHG_BATTERIE'
		-- Récupération de la planification du prochain changement de batterie actif
		--	en prenant en compte les éventuels jours exceptionnels
		SELECT @v_evc_datetime1 = MIN(EVC_DATETIME), @v_evc_datetime2 = REPLACE(SUBSTRING(CONVERT(varchar, CONVERT(time, MAX(EVC_DATETIME))), 1, 5), ':', 'h')
			FROM (SELECT TOP 2 CONVERT(datetime, CONVERT(date, DATEADD(day, EVC_ID, GETDATE()))) + CONVERT(datetime, CONVERT(time, EVC_HEURE)) EVC_DATETIME FROM (
			SELECT CASE WHEN EVC_ID > 0 THEN EVC_ID ELSE CASE WHEN EVC_ID = 0 THEN CASE WHEN ((DATEPART(hour, EVC_HEURE) = DATEPART(hour, GETDATE()) AND DATEPART(minute, EVC_HEURE) >= DATEPART(minute, GETDATE()))
			OR (DATEPART(hour, EVC_HEURE) > DATEPART(hour, GETDATE()))) THEN 0 ELSE EVC_ID + 7 END ELSE EVC_ID + 7 END END EVC_ID, EVC_HEURE FROM (
			SELECT EVC_JOUR - (((@@DATEFIRST + DATEPART(dw, GETDATE()) - 2) % 7) + 1) EVC_ID, EVC_HEURE FROM (
			SELECT CASE WHEN EVC_JOUR IS NOT NULL THEN EVC_JOUR ELSE DATEPART(dw, EVC_DATE) END EVC_JOUR, EVC_HEURE
			FROM CONFIG_EVT_ENERGIE WHERE EVC_AGV = @v_iag_idagv AND EVC_TYPEACT = @TYPE_CHANGEMENT_BATTERIE AND EVC_ACTIF = 1) CONFIG_EVT_ENERGIE) CONFIG_EVT_ENERGIE
			) CONFIG_EVT_ENERGIE ORDER BY EVC_ID, EVC_HEURE) CONFIG_EVT_ENERGIE
		IF EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND DATEDIFF(minute, GETDATE(), @v_evc_datetime1) <= @v_par_intervalle)
		BEGIN
			SET @v_dsp_iddefaut = @DEFA_UNPLANNED_CHANGE
			-- Renvoi des arguments pour la chaîne de formatage ou directement la chaîne formatée (OperatingScreens ou AGV)
			IF @v_lan_id IS NULL
				SELECT @v_evc_datetime2
			ELSE
				SELECT @v_dsp_information = REPLACE(LIB_LIBELLE, '%s', CONVERT(varchar(5), @v_evc_datetime2, 108)) FROM DEFAUT_SPV INNER JOIN LIBELLE ON LIB_TRADUCTION = DSP_IDTRADUCTIONINFORMATION
					WHERE DSP_ID = @v_dsp_iddefaut AND LIB_LANGUE = @v_lan_id
		END
		ELSE
		BEGIN
			SELECT @v_evc_datetime1 = IAG_HORODATE_ENERGIE, @v_evc_datetime2 = REPLACE((SUBSTRING(CONVERT(varchar, 100 + IAG_HORODATE_BATTERIE / 60), 2, 2) + ':' + SUBSTRING(CONVERT(varchar, 100 + IAG_HORODATE_BATTERIE % 60), 2, 2)), ':', 'h') FROM (
				SELECT IAG_HORODATE_ENERGIE, DATEDIFF(minute, IAG_HORODATE_ENERGIE, GETDATE()) IAG_HORODATE_BATTERIE
				FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv) INFO_AGV
			IF DATEDIFF(minute, @v_evc_datetime1, GETDATE()) <= @v_par_cycle
			BEGIN
				SET @v_dsp_iddefaut = @DEFA_UNCHARGED_BATTERY
				-- Renvoi des arguments pour la chaîne de formatage ou directement la chaîne formatée (OperatingScreens ou AGV)
				IF @v_lan_id IS NULL
					SELECT @v_evc_datetime2
				ELSE
					SELECT @v_dsp_information = REPLACE(LIB_LIBELLE, '%s', CONVERT(varchar(5), @v_evc_datetime2, 108)) FROM DEFAUT_SPV INNER JOIN LIBELLE ON LIB_TRADUCTION = DSP_IDTRADUCTIONINFORMATION
						WHERE DSP_ID = @v_dsp_iddefaut AND LIB_LANGUE = @v_lan_id
			END
		END
	END
	IF @v_mis_idmission IS NOT NULL
	BEGIN
		IF @v_eec_idevenement IS NOT NULL
		BEGIN
			IF (@v_det_iddescription IN (@DESC_EXECUTION_AUTOMATIQUE, @DESC_EXECUTION_MANUELLE))
			BEGIN
				UPDATE EVT_ENERGIE_EN_COURS SET EEC_ETAT = @ETAT_EVT_TERMINE WHERE EEC_ID = @v_eec_idevenement
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					UPDATE INFO_AGV SET IAG_HORODATE_ENERGIE = GETDATE(), IAG_DECHARGE = 0 WHERE IAG_ID = @v_iag_idagv
					SET @v_error = @@ERROR
				END
			END
			ELSE
			BEGIN
				UPDATE EVT_ENERGIE_EN_COURS SET EEC_ETAT = @ETAT_EVT_ENATTENTE, EEC_IDMISSION = NULL, EEC_IDOBJ = NULL
					WHERE EEC_ID = @v_eec_idevenement AND EEC_ETAT <> @ETAT_EVT_TERMINE
				SET @v_error = @@ERROR
			END
		END
	END
	ELSE
	BEGIN
		IF @v_type = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION = @TYPE_BATTERIE AND MIS_IDAGV = @v_iag_idagv AND MIS_IDETATMISSION IN (@ETAT_ENATTENTE, @ETAT_SUSPENDU))
			BEGIN
				DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR SELECT MIS_IDMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION = @TYPE_BATTERIE
					AND MIS_IDAGV = @v_iag_idagv AND MIS_IDETATMISSION IN (@ETAT_ENATTENTE, @ETAT_SUSPENDU)
				OPEN c_mission
				FETCH NEXT FROM c_mission INTO @v_mis_idmission
				WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
				BEGIN
					EXEC @v_status = INT_CANCELMISSION @v_mis_idmission
					SET @v_error = @@ERROR
					FETCH NEXT FROM c_mission INTO @v_mis_idmission
				END
				CLOSE c_mission
				DEALLOCATE c_mission
			END
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION = @TYPE_BATTERIE AND MIS_IDAGV = @v_iag_idagv
				AND MIS_IDETATMISSION IN (@ETAT_ENATTENTE, @ETAT_STOPPE, @ETAT_SUSPENDU))
			BEGIN
				DECLARE c_tache CURSOR LOCAL FAST_FORWARD FOR SELECT TAC_IDTACHE, TAC_IDORDRE
					FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = (SELECT MIS_IDMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION = @TYPE_BATTERIE AND MIS_IDAGV = @v_iag_idagv
					AND MIS_IDETATMISSION IN (@ETAT_ENATTENTE, @ETAT_STOPPE, @ETAT_SUSPENDU)) AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
				OPEN c_tache
				FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idordre
				WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
				BEGIN
					UPDATE TACHE SET TAC_IDETAT = @ETAT_ANNULE, TAC_DSCETAT = @DESC_ANNULATION, TAC_IDORDRE = NULL
						WHERE TAC_IDTACHE = @v_tac_idtache
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						IF @v_tac_idordre IS NOT NULL AND NOT EXISTS (SELECT 1 FROM INT_TACHE_MISSION WHERE TAC_IDORDRE = @v_tac_idordre)
						BEGIN
							UPDATE ORDRE_AGV SET ORD_IDETAT = @ETAT_ANNULE, ORD_DSCETAT = @DESC_ANNULATION
								WHERE ORD_IDORDRE = @v_tac_idordre
							SET @v_error = @@ERROR
						END
					END
					FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idordre
				END
				CLOSE c_tache
				DEALLOCATE c_tache
			END
			IF @v_status = @CODE_OK AND @v_error = 0
			BEGIN
				IF EXISTS (SELECT 1 FROM CONFIG_RSV_ENERGIE INNER JOIN CONFIG_OBJ_ENERGIE ON COE_ID = CRE_IDOBJ WHERE CRE_IDAGV = @v_iag_idagv AND COE_TYPE = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME)
				BEGIN
					IF EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) AND BAT_INFO_AGV = @v_iag_idagv)
					BEGIN
						SELECT TOP 1 @v_bat_id = BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) AND (BAT_INFO_AGV = @v_iag_idagv)
						SELECT TOP 1 @v_adr_idsysteme  = COE_ADRSYS, @v_adr_idbase  = COE_ADRBASE, @v_adr_idsousbase = COE_ADRSSBASE FROM CONFIG_RSV_ENERGIE INNER JOIN CONFIG_OBJ_ENERGIE ON COE_ID = CRE_IDOBJ
							WHERE CRE_IDAGV = @v_iag_idagv AND COE_TYPE = @TYPE_CHANGEMENT_BATTERIE_AUTOMATIQUE_AUTONOME
							AND NOT EXISTS (SELECT 1 FROM BATTERIE WHERE BAT_CONFIG_OBJ_ENERGIE = COE_ID)
						EXEC @v_status = INT_TRANSFERBATTERIE @v_iag_idagv, @v_bat_id, @v_adr_idsysteme, @v_adr_idbase, @v_adr_idsousbase
						SET @v_error = @@ERROR
						IF @v_status = @CODE_OK AND @v_error = 0
						BEGIN
							SELECT TOP 1 @v_bat_id = BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) ORDER BY BAT_DATELASTOPER ASC
							EXEC @v_status = INT_TRANSFERBATTERIE @v_iag_idagv, @v_bat_id
							SET @v_error = @@ERROR
						END
					END
					ELSE
					BEGIN
						SELECT TOP 1 @v_bat_id = BAT_ID FROM BATTERIE WHERE BAT_ID IN (2 * @v_iag_idagv - 1, 2 * @v_iag_idagv) ORDER BY BAT_DATELASTOPER ASC
						EXEC @v_status = INT_TRANSFERBATTERIE @v_iag_idagv, @v_bat_id
						SET @v_error = @@ERROR
					END
				END
			END
		END
		IF @v_status = @CODE_OK AND @v_error = 0
		BEGIN
			UPDATE EVT_ENERGIE_EN_COURS SET EEC_ETAT = @ETAT_EVT_TERMINE WHERE EEC_AGV = @v_iag_idagv AND EEC_ETAT <> @ETAT_EVT_TERMINE
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				UPDATE INFO_AGV SET IAG_HORODATE_ENERGIE = GETDATE(), IAG_ENCHARGE = 0, IAG_DECHARGE = 0 WHERE IAG_ID = @v_iag_idagv
				SET @v_error = @@ERROR
			END
		END
	END
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		SET @v_retour = @CODE_OK
		COMMIT TRAN
	END
	ELSE
	BEGIN
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
		ROLLBACK TRAN
	END
	RETURN @v_retour

