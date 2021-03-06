SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procedure		: SPV_DETECTEVTENERGIE
-- Paramètre d'entrée	:
-- Paramètre de sortie	:
-- Descriptif		: Cette procedure est appelée pour vérifier si de nouveaux
--			  evenements energie doivent etre declenche
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_DETECTEVTENERGIE]
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_idEvent int,
	@v_typeEvent tinyint,
	@v_agvEvent tinyint,
	@v_agvEnCharge bit,
	@v_par_intervalle varchar(128)

-- Déclaration des constantes d'états et de type
DECLARE
	@v_ENVOIBATTERIE tinyint,
	@v_ENVOICHARGE_PLAN tinyint,
	@v_SORTIECHARGE tinyint,
	@v_ENVOICHARGE_AUTO tinyint,
	@v_ETAT_ATTENTE tinyint,
	@v_ETAT_TERMINE tinyint

-- Définition des constantes
	SET @v_ENVOIBATTERIE = 1
	SET @v_ENVOICHARGE_PLAN = 2
	SET @v_SORTIECHARGE = 3
	SET @v_ENVOICHARGE_AUTO = 4
	SET @v_ETAT_ATTENTE = 1
	SET @v_ETAT_TERMINE = 3

	-- Récupération du paramètre indiquant l'intervalle minimum entre deux changements de batterie
	SELECT @v_par_intervalle = '120'
	SELECT @v_par_intervalle = PAR_VAL FROM PARAMETRE where PAR_NOM = 'INT_CHG_BATTERIE'

	-- Récuperation des événements à executer
	DECLARE c_newEvent CURSOR FAST_FORWARD LOCAL FOR SELECT EVC_ID,EVC_TYPEACT, EVC_AGV, IAG_ENCHARGE
		FROM CONFIG_EVT_ENERGIE, INFO_AGV WHERE EVC_AGV = IAG_ID
		AND (datepart(hour, EVC_HEURE) = datepart(hour,getdate()) AND datepart(minute, EVC_HEURE) = datepart(minute,getdate())
		AND ((EVC_JOUR = ((@@DATEFIRST + DATEPART(dw, GETDATE()) - 2) % 7) + 1)
		OR (datepart(day, EVC_DATE) = datepart(day, getdate()) AND datepart(month, EVC_DATE) = datepart(month, getdate())))
		AND (EVC_TYPEACT IN (@v_ENVOICHARGE_PLAN, @v_ENVOICHARGE_AUTO, @v_SORTIECHARGE) OR (EVC_TYPEACT = @v_ENVOIBATTERIE AND (IAG_HORODATE_ENERGIE IS NULL OR (DATEDIFF(minute, IAG_HORODATE_ENERGIE, GETDATE()) > @v_par_intervalle)))))
		AND EVC_ACTIF = 1 AND IAG_OPERATIONNEL = 'O'
		AND NOT EXISTS (SELECT 1 FROM EVT_ENERGIE_EN_COURS WHERE EEC_AGV = EVC_AGV AND EEC_ETAT <> @v_ETAT_TERMINE)
	-- ouverture du curseur
	open c_newEvent
	fetch next from c_newEvent into @v_idEvent, @v_typeEvent, @v_agvEvent, @v_agvEnCharge
	while (@@FETCH_STATUS = 0)
	begin
		IF ((@v_typeEvent IN (@v_ENVOIBATTERIE, @v_ENVOICHARGE_PLAN, @v_ENVOICHARGE_AUTO) AND @v_agvEnCharge = 0)
			OR (@v_typeEvent = @v_SORTIECHARGE AND @v_agvEnCharge = 1))
		begin
 			-- creation d'un evenement d'envoi en changement batterie
			insert into EVT_ENERGIE_EN_COURS (EEC_IDEVT, EEC_DATE, EEC_ETAT, EEC_AGV, EEC_TYPEACT)
				values (@v_idEvent, GETDATE(), @v_ETAT_ATTENTE, @v_agvEvent, @v_typeEvent)
		end
		fetch next from c_newEvent into @v_idEvent, @v_typeEvent, @v_agvEvent, @v_agvEnCharge
	end
	-- fermeture du curseur
	close c_newEvent
	deallocate c_newEvent
	if @@ERROR <> 0
		return(@@ERROR)
	else
		return(0)


