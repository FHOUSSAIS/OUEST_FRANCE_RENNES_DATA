SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_CHECKPLANIFICATION
-- Paramétre d'entrée	: 
-- Paramétre de sortie	: 
-- Descriptif		: Gestion de la planification des modes d'exploitations
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_CHECKPLANIFICATION]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_error smallint,
	@v_retour smallint,
	@v_pla_id int,
	@v_pla_mode_exploitation int,
	@v_pla_info_agv tinyint,
	@v_mode int,
	@v_agv varchar(100),
	@v_jour int,
	@v_hour int,
	@v_remotestop varchar(128)

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint
	
-- Déclaration des constantes de mode d'exploitation
DECLARE
	@MODE_TEST int
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @MODE_TEST = 1
	
-- Initialisation des variables
	SET @v_retour = @CODE_OK
	
	SELECT @v_remotestop = PAR_VAL FROM PARAMETRE WHERE PAR_NOM = 'REMOTE_STOP'
	IF @v_remotestop = 0
	BEGIN
		DECLARE c_planification CURSOR LOCAL FAST_FORWARD FOR SELECT PLA_ID, PLA_MODE_EXPLOITATION, PLA_INFO_AGV
			FROM PLANIFICATION LEFT OUTER JOIN INFO_AGV ON IAG_ID = PLA_INFO_AGV
			WHERE PLA_ACTIF = 1 AND PLA_PROCHAINE_EXECUTION IS NOT NULL
			AND (IAG_ID IS NULL OR (IAG_MODE_EXPLOIT <> @MODE_TEST))
			AND CONVERT(varchar(8), PLA_PROCHAINE_EXECUTION, 112) = CONVERT(varchar(8), GETDATE(), 112)
			AND CONVERT(varchar(5), PLA_PROCHAINE_EXECUTION, 108) = CONVERT(varchar(5), GETDATE(), 108)
			ORDER BY PLA_MODE_EXPLOITATION, PLA_INFO_AGV
		OPEN c_planification
		FETCH NEXT FROM c_planification INTO @v_pla_id, @v_pla_mode_exploitation, @v_pla_info_agv
		SET @v_mode = @v_pla_mode_exploitation
		SET @v_agv = @v_pla_info_agv
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = DATEADD(d, 7, PLA_PROCHAINE_EXECUTION)
				WHERE PLA_ID = @v_pla_id
			FETCH NEXT FROM c_planification INTO @v_pla_id, @v_pla_mode_exploitation, @v_pla_info_agv
			IF ((@v_mode <> @v_pla_mode_exploitation) OR (@@FETCH_STATUS != 0))
			BEGIN
				EXEC @v_error = INT_SETMODEEXPLOITATION @v_mode, @v_agv
				IF ((@v_error <> @CODE_OK) AND (@v_retour = @CODE_OK))
					SET @v_retour = @CODE_KO
				SET @v_mode = @v_pla_mode_exploitation
				SET @v_agv = @v_pla_info_agv
			END
			ELSE
			BEGIN
				IF @v_agv IS NOT NULL AND @v_pla_info_agv IS NOT NULL
					SET @v_agv = @v_agv + ', ' + CONVERT(varchar, @v_pla_info_agv)
				ELSE IF @v_pla_info_agv IS NULL
					SET @v_agv = NULL
			END
		END
		CLOSE c_planification
		DEALLOCATE c_planification
		SET @v_jour = ((@@DATEFIRST + DATEPART(dw, GETDATE()) - 2) % 7) + 1
		SET @v_hour = CONVERT(varchar(2), GETDATE(), 108) * 60 + SUBSTRING(CONVERT(varchar(5), GETDATE(), 108), 4, 2)
		DECLARE c_planification CURSOR LOCAL FAST_FORWARD FOR SELECT PLA_MODE_EXPLOITATION, IAG_ID
			FROM PLANIFICATION LEFT OUTER JOIN INFO_AGV ON IAG_ID = ISNULL(PLA_INFO_AGV, IAG_ID)
			WHERE PLA_ACTIF = 1
			AND (IAG_ID IS NULL OR (IAG_MODE_EXPLOIT <> @MODE_TEST))			
			AND ((PLA_JOUR_DEBUT < @v_jour AND PLA_JOUR_FIN > @v_jour)
			OR (PLA_JOUR_DEBUT = @v_jour AND PLA_HEURE_DEBUT <= @v_hour AND PLA_JOUR_FIN > @v_jour)
			OR (PLA_JOUR_DEBUT = @v_jour AND PLA_HEURE_DEBUT <= @v_hour AND PLA_JOUR_FIN = @v_jour AND PLA_HEURE_FIN > @v_hour)
			OR (PLA_JOUR_DEBUT < @v_jour AND PLA_JOUR_FIN = @v_jour AND PLA_HEURE_FIN > @v_hour))
			AND IAG_MODE_EXPLOIT <> PLA_MODE_EXPLOITATION
			ORDER BY PLA_MODE_EXPLOITATION, IAG_ID
		OPEN c_planification
		FETCH NEXT FROM c_planification INTO @v_pla_mode_exploitation, @v_pla_info_agv
		SET @v_mode = @v_pla_mode_exploitation
		SET @v_agv = @v_pla_info_agv
		WHILE @@FETCH_STATUS = 0
		BEGIN
			FETCH NEXT FROM c_planification INTO @v_pla_mode_exploitation, @v_pla_info_agv
			IF ((@v_mode <> @v_pla_mode_exploitation) OR (@@FETCH_STATUS != 0))
			BEGIN
				EXEC @v_error = INT_SETMODEEXPLOITATION @v_mode, @v_agv
				IF ((@v_error <> @CODE_OK) AND (@v_retour = @CODE_OK))
					SET @v_retour = @CODE_KO
				SET @v_mode = @v_pla_mode_exploitation
				SET @v_agv = @v_pla_info_agv
			END
			ELSE
			BEGIN
				IF @v_agv IS NOT NULL AND @v_pla_info_agv IS NOT NULL
					SET @v_agv = @v_agv + ', ' + CONVERT(varchar, @v_pla_info_agv)
				ELSE IF @v_pla_info_agv IS NULL
					SET @v_agv = NULL
			END
		END
		CLOSE c_planification
		DEALLOCATE c_planification
		UPDATE PLANIFICATION SET PLA_PROCHAINE_EXECUTION = DATEADD(d, 7, PLA_PROCHAINE_EXECUTION)
			WHERE PLA_PROCHAINE_EXECUTION < GETDATE() AND PLA_ACTIF = 1
	END
	RETURN @v_retour


