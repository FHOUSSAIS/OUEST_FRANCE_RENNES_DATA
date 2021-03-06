SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: PIL_UPDATEAGV
-- Paramètre d'entrée	: @v_iag_id : Identifiant
--			  @v_iag_horametre : horametre de l'AGV
--			  @v_iag_pos_x : Position x
--			  @v_iag_pos_y : Position y
--			  @v_iag_pos_theta : Position théta
--			  @v_iag_agv_genant : AGV gênant
--			  @v_iag_bloc_genant : Bloc gênant
--			  @v_iag_distance : Distance autorisée
--			  @v_interactions : Chaîne de caractères indiquant les interactions
--				au format : 'vers;type;physique;logique;réservation;bloc\nvers;type;...'
--			  @v_blocs : Chaîne de caractères indiquant les blocs réservés
--				au format : 'bloc1;bloc2;...'
--			  @v_mode : Mode
--			    0 : Manuel
--			    1 : Automatique
--			  @v_tauxBatterie : Taux decharge batterie
--			  @v_intensiteBatterie : Intensite batterie
--			  @v_tensionBatterie : Tension batterie
--			  @v_pause : Pause
--			    0 : Inactive
--			    1 : Demandée
--			    2 : Active
--			  @v_arretDistance : Arrêt à distance
--			    0 : Non
--			    1 : Oui
--			  @v_vitesseNulle : Vitesse nulle
--			    0 : Non
--			    1 : Oui
--			  @v_arretPointArret : l'agv est-il arrete sur point action
--			    0 : Non
--			    1 : oui
--			  @v_arretConflit : Conflit
--			    0 : Non
--			    1 : oui
-- Paramètre de sortie	: 
-- Descriptif		: Mise à jour d'informations de l'AGV, des informations de conflits
--			  et d'interaction
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[PIL_UPDATEAGV]
	@v_iag_id tinyint,
	@v_iag_horametre float,
	@v_iag_pos_x int,
	@v_iag_pos_y int,
	@v_iag_pos_theta int,
	@v_iag_genant tinyint = NULL,
	@v_iag_bloc_genant varchar(32) = NULL,
	@v_iag_distance int = NULL,
	@v_interactions varchar(8000) = NULL,
	@v_blocs varchar(8000) = NULL,
    @v_mode bit,
	@v_tauxBatterie float,
	@v_intensiteBatterie float,
	@v_tensionBatterie float,
	@v_pause tinyint,
	@v_arretDistance bit,
	@v_vitesseNulle bit,
	@v_arretPointArret bit,
	@v_arretConflit bit
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_retour int,
	@v_charindex int,
	@v_interaction varchar(8000),
	@v_vers tinyint,
	@v_type tinyint,
	@v_sPhysique int,
	@v_sLogique int,
	@v_sReservation int,
	@v_sBloc int,
	@v_i smallint,
	@v_bloc varchar(8000)

-- Initialisation des variables
	SELECT @v_error = 0

	UPDATE INFO_AGV SET IAG_POS_X = @v_iag_pos_x, IAG_POS_Y = @v_iag_pos_y, IAG_POS_THETA = @v_iag_pos_theta,
		IAG_GENANT = @v_iag_genant, IAG_BLOCGENANT = @v_iag_bloc_genant, IAG_DISTANCE = @v_iag_distance,
		IAG_HORAMETRE  = CASE WHEN IAG_HORAMETRE <= @v_iag_horametre THEN @v_iag_horametre ELSE IAG_HORAMETRE END,
		IAG_MODE = @v_mode, IAG_TAUXBATTERIE = @v_tauxBatterie,
		IAG_INTENSITEBATTERIE = @v_intensiteBatterie, IAG_TENSIONBATTERIE = @v_tensionBatterie,
		IAG_PAUSE = @v_pause, IAG_ARRETDISTANCE = @v_arretDistance, IAG_VITESSENULLE = @v_vitesseNulle,
		IAG_MOTIFARRETDISTANCE = CASE WHEN (IAG_ARRETDISTANCE = 1 AND @v_arretDistance = 0) THEN 0 ELSE IAG_MOTIFARRETDISTANCE END,
		IAG_ARRETPOINTARRET = @v_arretPointArret, IAG_ARRETCONFLIT = @v_arretConflit
		WHERE IAG_ID = @v_iag_id
	SELECT @v_error = @@ERROR
	IF @v_error = 0
	BEGIN
		IF @v_interactions IS NOT NULL AND @v_interactions <> ''
		BEGIN
			SELECT @v_charindex = CHARINDEX(CHAR(10), @v_interactions)
			WHILE ((@v_charindex <> 0) AND (@v_error = 0))
			BEGIN
				SELECT @v_interaction = SUBSTRING(@v_interactions, 1, @v_charindex - 1)
				SELECT @v_interactions = SUBSTRING(@v_interactions, @v_charindex + 1, LEN(@v_interactions) - @v_charindex)
				SELECT @v_i = 0
				SELECT @v_charindex = CHARINDEX(';', @v_interaction)
				WHILE ((@v_i <= 4) AND (@v_charindex <> 0))
				BEGIN
					IF @v_i = 0
						SELECT @v_vers = SUBSTRING(@v_interaction, 1, @v_charindex - 1)
					ELSE IF @v_i = 1
						SELECT @v_type = SUBSTRING(@v_interaction, 1, @v_charindex - 1)
					ELSE IF @v_i = 2
						SELECT @v_sPhysique = SUBSTRING(@v_interaction, 1, @v_charindex - 1)
					ELSE IF @v_i = 3
						SELECT @v_sLogique = SUBSTRING(@v_interaction, 1, @v_charindex - 1)
					ELSE IF @v_i = 4
					BEGIN
						SELECT @v_sReservation = SUBSTRING(@v_interaction, 1, @v_charindex - 1)
						SELECT @v_sBloc = SUBSTRING(@v_interaction, @v_charindex + 1, LEN(@v_interaction) - @v_charindex)
					END
					SELECT @v_interaction = SUBSTRING(@v_interaction, @v_charindex + 1, LEN(@v_interaction) - @v_charindex)
					SELECT @v_charindex = CHARINDEX(';', @v_interaction)
					SELECT @v_i = @v_i + 1
				END
				IF @v_type = 0 AND EXISTS (SELECT 1 FROM INTERACTION WHERE INR_DE = @v_iag_id AND INR_VERS = @v_vers AND ((INR_TYPE <> @v_type)
					OR (INR_PHYSIQUE IS NOT NULL) OR (INR_LOGIQUE IS NOT NULL) OR (INR_RESERVATION IS NOT NULL) OR (INR_BLOC IS NOT NULL)))
					UPDATE INTERACTION SET INR_TYPE = @v_type, INR_PHYSIQUE = NULL, INR_LOGIQUE = NULL, INR_RESERVATION = NULL, INR_BLOC = NULL
						WHERE INR_DE = @v_iag_id AND INR_VERS = @v_vers
				ELSE IF @v_type IN (1, 2, 3, 4, 5) AND EXISTS (SELECT 1 FROM INTERACTION WHERE INR_DE = @v_iag_id AND INR_VERS = @v_vers AND ((INR_TYPE <> @v_type)
					OR (INR_PHYSIQUE <> @v_sPhysique) OR (INR_LOGIQUE <> @v_sLogique) OR (INR_RESERVATION <> @v_sReservation) OR (INR_BLOC <> @v_sBloc)))
					UPDATE INTERACTION SET INR_TYPE = @v_type, INR_PHYSIQUE = @v_sPhysique, INR_LOGIQUE = @v_sLogique, INR_RESERVATION = @v_sReservation, INR_BLOC = @v_sBloc
						WHERE INR_DE = @v_iag_id AND INR_VERS = @v_vers
				SELECT @v_error = @@ERROR
				SELECT @v_charindex = CHARINDEX(CHAR(10), @v_interactions)
			END
		END
		ELSE
			UPDATE INTERACTION SET INR_TYPE = 0, INR_PHYSIQUE = NULL, INR_LOGIQUE = NULL, INR_RESERVATION = NULL, INR_BLOC = NULL
				WHERE INR_DE = @v_iag_id AND ((INR_TYPE <> 0) OR (INR_PHYSIQUE IS NOT NULL) OR (INR_LOGIQUE IS NOT NULL) OR (INR_RESERVATION IS NOT NULL) OR (INR_BLOC IS NOT NULL))
	END
	IF @v_error = 0
	BEGIN
		IF @v_blocs IS NOT NULL AND @v_blocs <> ''
		BEGIN
			DECLARE @v_reservation table(BLOC varchar(32) NOT NULL)
			SELECT @v_charindex = CHARINDEX(';', @v_blocs)
			WHILE ((@v_charindex <> 0) AND (@v_error = 0))
			BEGIN
				SELECT @v_bloc = SUBSTRING(@v_blocs, 1, @v_charindex - 1)
				SELECT @v_blocs = SUBSTRING(@v_blocs, @v_charindex + 1, LEN(@v_blocs) - @v_charindex)
				INSERT INTO @v_reservation VALUES (@v_bloc)
				SELECT @v_error = @@ERROR
				SELECT @v_charindex = CHARINDEX(';', @v_blocs)
			END
			DELETE RESERVATION WHERE RES_INFO_AGV = @v_iag_id AND NOT EXISTS (SELECT 1 FROM @v_reservation WHERE BLOC = RES_BLOC)
			INSERT INTO RESERVATION (RES_INFO_AGV, RES_BLOC) SELECT @v_iag_id, BLOC FROM @v_reservation WHERE NOT EXISTS (SELECT 1 FROM RESERVATION WHERE RES_BLOC = BLOC)
		END
		ELSE
			DELETE RESERVATION WHERE RES_INFO_AGV = @v_iag_id
	END

