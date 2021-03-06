SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modification du Nombre de Bobines Maximal en Hauteur
-- @v_idSysteme		: ID système de l'allée
-- @v_idBase		: ID Base de l'allée 
-- @v_idSousBase	: ID Sous base de l'allée
-- @v_typeLaize		: Type de laize
-- @v_nbBobine		: Nb bobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_IHM_STK_NBLAIZEHAUTEUR]
	@v_idSysteme  bigint,
	@v_idBase     bigint,
	@v_idSousBase bigint,
	@v_typeLaize  VARCHAR(100),
	@v_nbBobine   int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int
DECLARE @CODE_KO_ALLEE_MISSIONENCOURS SMALLINT,
		@CODE_KO_ALLEE_NON_VIDE INT,
		@ETATTAC_ENATTENTE TINYINT,
		@ETATTAC_ENCOURS TINYINT

declare @retour      int,
		@local       int,
		@procStock   varchar(128),
		@chaineTrace varchar(7500)
declare @lze_champ   varchar(100),
		@sql_cmde    varchar(max)

set @CODE_OK = 0
set @CODE_KO = 1
SET @ETATTAC_ENATTENTE = 1
SET @ETATTAC_ENCOURS = 2
SET @CODE_KO_ALLEE_MISSIONENCOURS = -1400
SET @CODE_KO_ALLEE_NON_VIDE = -1399

set @retour = @CODE_OK
set @procStock = 'SPC_IHM_STK_NBLAIZEHAUTEUR'

	-- Vérification Allée Vide
	if exists( select 1 from INT_CHARGE_VIVANTE where CHG_IDSYSTEME = @v_idSysteme and CHG_IDBASE = @v_idBase and CHG_IDSOUSBASE = @v_idSousBase )
	begin
		return @CODE_KO_ALLEE_NON_VIDE
	end
	
-- Vérification des interdictions : l'allée ne doit pas être contenu dans une mission
	IF @retour = @CODE_OK
	BEGIN
		IF EXISTS (SELECT 1 FROM INT_TACHE_MISSION
					WHERE TAC_IDSYSTEMEEXECUTION = @v_idSysteme AND TAC_IDBASEEXECUTION = @v_idBase AND TAC_IDSOUSBASEEXECUTION = @v_idSousBase
							AND ((TAC_IDACTION = 4 AND TAC_IDETATTACHE IN (@ETATTAC_ENATTENTE, @ETATTAC_ENCOURS))
								 OR (TAC_IDACTION = 2 AND TAC_IDETATTACHE = @ETATTAC_ENCOURS)))
			return @CODE_KO_ALLEE_MISSIONENCOURS
	END

	-- Récupération du type de bobine en fonction de la laize
	 set @lze_champ = case @v_typeLaize 
						when  '1/2_638'   then 'NLH_NBDEMILAIZE'
						when  '1/2_700'   then 'NLH_NBDEMILAIZE'
						when  '3/4_957'   then 'NLH_NBTROISQUARTLAIZE'
						when  '3/4_1050'  then 'NLH_NBTROISQUARTLAIZE'
						when   'PL_1276'  then 'NLH_NBPLEINELAIZE'
						when   'PL_1400'  then 'NLH_NBPLEINELAIZE'
	end

	-- Vérification Nb Bobines
	if     ( @v_typeLaize = '1/2_638'  and @v_nbBobine > 9 )
	    or ( @v_typeLaize = '1/2_700'  and @v_nbBobine > 8 ) 
	    or ( @v_typeLaize = '3/4_957'  and @v_nbBobine > 6 )  
	    or ( @v_typeLaize = '3/4_1050' and @v_nbBobine > 5 )
	    or ( @v_typeLaize = 'PL_1276'  and @v_nbBobine > 4 ) 
	    or ( @v_typeLaize = 'PL_1400'  and @v_nbBobine > 4 )
	    or ( @v_nbBobine < 1 )
	begin
		return -1179 -- Nombre de Bobines Incorrect
	end	
/*
UPDATE SPC_STK_NBLAIZEHAUTEUR
SET @lze_champ = @v_nbBobine
WHERE NLH_IDSYSTEME = @v_idSysteme
AND NLH_IDBASE = @v_idBase
AND NLH_IDSOUSBASE = @v_idSousBase
*/
	-- Si problème de paramétrage on ajoute l'adresse
	IF NOT EXISTS (SELECT 1 from SPC_STK_NBLAIZEHAUTEUR where NLH_IDSYSTEME = @v_idSysteme AND NLH_IDBASE = @v_idBase AND NLH_IDSOUSBASE = @v_idSousBase)
	BEGIN
		set @sql_cmde = 'INSERT INTO [dbo].[SPC_STK_NBLAIZEHAUTEUR]
			([NLH_IDSYSTEME]
           ,[NLH_IDBASE]
           ,[NLH_IDSOUSBASE]
           ,[NLH_NBPLEINELAIZE]
           ,[NLH_NBTROISQUARTLAIZE]
           ,[NLH_NBDEMILAIZE])
		   VALUES
		   (' + CONVERT( varchar, @v_idSysteme ) 
		   +',' + CONVERT( varchar, @v_idBase )
		   +',' + CONVERT( varchar, @v_idSousBase )
		   + ',0,0,0)'
		   print @sql_cmde
		exec( @sql_cmde )
		set @retour = @@ERROR		
	END
	
	if( @retour = @CODE_OK )
	BEGIN
		set @sql_cmde = 'update SPC_STK_NBLAIZEHAUTEUR set ' + @lze_champ + ' = ' + CONVERT( varchar, @v_nbBobine )
				+ ' where NLH_IDSYSTEME = ' + CONVERT( varchar, @v_idSysteme ) 
				+ ' and NLH_IDBASE = ' + CONVERT( varchar, @v_idBase )
				+ ' and NLH_IDSOUSBASE = ' + CONVERT( varchar, @v_idSousBase )
		exec( @sql_cmde )
		set @retour = @@ERROR
	END

	if( @retour <> @CODE_OK )
	begin
		set @chaineTrace = 'Update NB LAIZE HAUTEUR' + CONVERT( varchar, ISNULL( @retour, -1 ) )
		exec INT_ADDTRACESPECIFIQUE @procStock, 'ERREUR', @chaineTrace
		
		set @retour = -1180 -- Erreur Interne
	end

	-- Ajout d'une trace de suivi
	IF @retour = @CODE_OK
	BEGIN
		SET @ChaineTrace = 'Modification NbMaxBobines/Hauteur ('+convert(varchar,@v_nbBobine)
					+'), Laize (' +convert(varchar,@v_typeLaize)
					+'), Allée '  + (SELECT ADr_ADRESSE FROM INT_ADRESSE WHERE ADR_IDSYSTEME=@v_idSysteme AND ADR_IDBASE=@v_idBase AND ADR_IDSOUSBASE=@v_idSousBase)
		EXEC INT_ADDTRACESPECIFIQUE '[IHM]', '[TRCSTK]', @ChaineTrace
	END

	return @retour
	
END

