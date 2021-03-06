SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
----------------------------------------------------------------------------------------
-- Procedure        : [SPC_ATT_CRITERES_CALCULES]
-- Paramètres d'entrées :
--	            @v_idCritere : identifiant du critère à calculer
--	            @v_idAgv : identifnant de l'AGV en cours d'attribution
-- Paramètres de sortie :
-- Descriptif           : Calcul des critères missions calculés spécifiques
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date		: 10/05/2010
-- Auteur	: CAU
-- Libellé	: Création
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPC_ATT_CRITERES_CALCULES]
@p_idCritere int,
@p_idAgv tinyint,
@p_parametre varchar(3500)

AS
BEGIN
--constantes
declare @CODE_OK int
declare @PROCSTOCK varchar(30)
--declaration des variables
declare @v_retour int
declare @v_value int
declare	@v_chaineTrace varchar (100)
declare @v_idMission int
declare @v_idDemande varchar(20)
declare @v_DateMission datetime
declare @v_idTache int
DECLARE @AlleeCourante BIGINT
DECLARE @BasePremiereTacheMission BIGINT

-- init cste
set @CODE_OK = 0
set @PROCSTOCK='SPC_ATT_CRITERES_CALCULES'
-- init var
set @v_retour = @CODE_OK
set @v_value = 0



/*set @v_chaineTrace ='Debut Traitement pour critere:'+convert(varchar,@p_idCritere)
EXEC INT_ADDTRACESPECIFIQUE @PROCSTOCK, '[DBGATT]' ,@v_chaineTrace*/

-- -------------------------------------------------------------------------------
-- Test si la mission est depuis le stock
-- -------------------------------------------------------------------------------
IF (@p_idCritere = -1)
BEGIN
	-- Lancement du curseur sur les missions pour exemple
	DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR 
	SELECT DISTINCT MIS_IDMISSION, TAC_IDTACHE
		FROM INT_MISSION_VIVANTE
		INNER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
		WHERE MIS_IDETATMISSION = 1 AND TAC_POSITION = 1
	OPEN c_mission
	FETCH NEXT FROM c_mission INTO @v_idMission, @v_idTache
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		set @v_value = 0
		IF EXISTS (SELECT 1 from INT_TACHE_MISSION
			inner join INT_ADRESSE on ADR_IDSYSTEME = TAC_IDSYSTEMEEXECUTION and  ADR_IDBASE = TAC_IDBASEEXECUTION and ADR_IDSOUSBASE = TAC_IDSOUSBASEEXECUTION
			where TAC_IDTACHE = @v_idTache and ADR_IDTYPEMAGASIN = 3 and ADR_MAGASIN = 2 and ADR_ALLEE = 1 and ADR_COULOIR = 1 and ADR_COTE in (1,2) and ADR_RACK <>0)
			SET @v_value = 1

		--Est-ce que mon AGV n'est pas déjà dans cette allée?
		select @AlleeCourante = INFO_AGV.IAG_BASE_DEST from INFO_AGV where INFO_AGV.IAG_ID = @p_idAgv
		SELECT @BasePremiereTacheMission = INT_TACHE_MISSION.TAC_IDBASEEXECUTION from INT_TACHE_MISSION
			where INT_TACHE_MISSION.TAC_POSITION = 1 and INT_TACHE_MISSION.TAC_IDMISSION = @v_idMission
		-- Si oui, on ne prend pas la mission
		IF @AlleeCourante = @BasePremiereTacheMission
			set @v_value = 0

		-- Mise a jour du critere de la mission
		EXEC INT_SETCRITEREMISSION @p_idCritere, @v_idMission, @v_value	
		
		FETCH NEXT FROM c_mission INTO @v_idMission, @v_idTache
	END
	CLOSE c_mission
	DEALLOCATE c_mission
END

-- -------------------------------------------------------------------------------
-- Test si la mission est depuis les racks A9 - A17
-- -------------------------------------------------------------------------------
IF (@p_idCritere = -2)
BEGIN
	-- Lancement du curseur sur les missions pour exemple
	DECLARE c_mission CURSOR LOCAL FAST_FORWARD FOR 
	SELECT DISTINCT MIS_IDMISSION, TAC_IDTACHE
		FROM INT_MISSION_VIVANTE
		INNER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
		WHERE MIS_IDETATMISSION = 1 AND TAC_POSITION = 1
	OPEN c_mission
	FETCH NEXT FROM c_mission INTO @v_idMission, @v_idTache
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		set @v_value = 0
		-- Mission prenable
		IF EXISTS (SELECT 1 from INT_TACHE_MISSION
			inner join INT_ADRESSE on ADR_IDSYSTEME = TAC_IDSYSTEMEEXECUTION and  ADR_IDBASE = TAC_IDBASEEXECUTION and ADR_IDSOUSBASE = TAC_IDSOUSBASEEXECUTION
			where TAC_IDTACHE = @v_idTache and ADR_IDTYPEMAGASIN = 3 and ADR_MAGASIN = 2 and ADR_ALLEE = 1 and ADR_COULOIR = 1 and ADR_COTE in (1,2) and ADR_RACK in(9,11,13,15,17))
			SET @v_value = 1

		--Est-ce que mon AGV n'est pas déjà dans cette allée?
		select @AlleeCourante = INFO_AGV.IAG_BASE_DEST from INFO_AGV where INFO_AGV.IAG_ID = @p_idAgv
		SELECT @BasePremiereTacheMission = INT_TACHE_MISSION.TAC_IDBASEEXECUTION from INT_TACHE_MISSION
			where INT_TACHE_MISSION.TAC_POSITION = 1 and INT_TACHE_MISSION.TAC_IDMISSION = @v_idMission
		-- Si oui, on ne prend pas la mission
		IF @AlleeCourante = @BasePremiereTacheMission
			set @v_value = 0

		-- Mise a jour du critere de la mission
		EXEC INT_SETCRITEREMISSION @p_idCritere, @v_idMission, @v_value	
		
		FETCH NEXT FROM c_mission INTO @v_idMission, @v_idTache
	END
	CLOSE c_mission
	DEALLOCATE c_mission
END

return @v_retour
END

