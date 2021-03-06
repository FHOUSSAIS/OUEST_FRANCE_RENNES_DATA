SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
----------------------------------------------------------------------------------------
-- Procedure       		:	[[SPC_ATT_VARIABLES_CALCULEES]]
-- Paramètres d'entrées 	: 	@p_idvariable int	:	identifiant de la variable à évaluer
--				:	@p_idtypevariable int	: Type
--				:	@p_idagv tinyint	:	identifiant de l'Agv
--				:	@p_parametre varchar(3500)	: Valeur du paramètre
--	            		  	
-- Paramètres de sortie :	
-- Descriptif           	: 	Mettre à jour les variables de l'attribution
-----------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[SPC_ATT_VARIABLES_CALCULEES]
	@p_idvariable int, 
	@p_idtypevariable int, 
	@p_idagv tinyint, 
	@p_parametre varchar(3500)
AS
BEGIN

-- Déclarations des cstes
declare @PROCSTOCK varchar(30)
declare @ETAT_ENATTENTE INT = 2
declare @DESC_ENVOYE INT= 13
declare @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE int = 1
declare @TYPE_NOMBREAGVSDESTINATIONCOURANTEZONEPARAMETREE int = 2
declare @TYPE_NOMBREAGVSDESTINATIONFUTUREBASEPARAMETREE int = 4
declare @TYPE_NOMBREAGVSDESTINATIONFUTUREZONEPARAMETREE int = 5
declare @TYPE_NOMBREAGVSORIGINEBASEPARAMETREE int = 11
declare @TYPE_NOMBREAGVSORIGINEZONEPARAMETREE int = 12

-- Déclarations des variables
declare @retour int
declare @v_value int
declare	@v_chaineTrace varchar (100)

declare @v_idbase_reception			bigint = 144116291882516737
declare @IDBASEENTREE_DEMAC_5		bigint = 144118490906034433
declare @IDBASE_ZA1					bigint = 360291273019556097
declare @IDBASE_ZA2					bigint = 144118490906034433
declare @v_nbagv					int = 0


-- Initialisation des variables - cstes
set @PROCSTOCK='SPC_ATT_VARIABLES_CALCULEES'
set @v_value = 0

/*set @v_chaineTrace ='Debut Traitement pour variable:'+convert(varchar,@p_idvariable)
EXEC INT_ADDTRACESPECIFIQUE @PROCSTOCK, '[DBGATT]' ,@v_chaineTrace*/

-----------------------------------------------------
-- AGV Gênant
-----------------------------------------------------
if (@p_idvariable = -1)
begin
	 SET @v_value = 0
     IF EXISTS (select 1 from INTERACTION
                  where  INR_PHYSIQUE IS NOT NULL
                  AND INR_VERS = @p_idagv
                  AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IdAgv = INR_VERS
                  ))
            BEGIN
                  SET @v_value = 1
            END
            EXEC @retour= INT_SETVARIABLE @p_idvariable , @v_value    
end

-----------------------------------------------------
-- AGV En direction ou dans les bases proches reception
-----------------------------------------------------
if (@p_idvariable = -2)
begin
	SET @v_value = 0	
		/*Si un AGV est présent dans les bases proches de la réception*/
		IF EXISTS (SELECT 1 FROM INFO_AGV
					inner join INT_ADRESSE on ADR_IDBASE = IAG_BASE_DEST
					WHERE IAG_OPERATIONNEL = 'O' AND ((ADR_RACK in (12,14,16,18,23,25,27)))
					AND IAG_ID <> @p_idAgv )
			SET @v_value = 1

		/*ou si l'autre AGV est en direction de la base de Reception*/
		exec @v_nbagv = SPC_AGV_GETNBAGV @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE, @v_idbase_reception , @p_idagv, 1, 0
		IF @v_nbagv > 0
			SET @v_value = 1

		/*Ou depuis de la ZA1*/
		exec @v_nbagv = SPC_AGV_GETNBAGV @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE, @IDBASE_ZA1 , @p_idagv, 1, 0
		IF @v_nbagv > 0
			SET @v_value = 1
			
		/*Ou déjà en direction de la ZA1*/
		exec @v_nbagv = SPC_AGV_GETNBAGV @TYPE_NOMBREAGVSORIGINEBASEPARAMETREE, @IDBASE_ZA1 , @p_idagv, 1, 0
		IF @v_nbagv > 0
			SET @v_value = 1

     EXEC @retour= INT_SETVARIABLE @p_idvariable , @v_value    
end

-----------------------------------------------------
-- AGV En direction ou en ZA1
-----------------------------------------------------
if (@p_idvariable = -4)
begin
	SET @v_value = 0
	exec @v_nbagv = SPC_AGV_GETNBAGV @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE, @IDBASE_ZA1 , @p_idagv, 1, NULL
	IF @v_nbagv > 0
		SET @v_value = 1

     EXEC @retour= INT_SETVARIABLE @p_idvariable , @v_value
end

-----------------------------------------------------
-- AGV En direction ou en DEMAC_5
-----------------------------------------------------
if (@p_idvariable = -5)
begin
	SET @v_value = 0
	exec @v_nbagv = SPC_AGV_GETNBAGV @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE, @IDBASEENTREE_DEMAC_5 , @p_idagv, 1, NULL
	IF @v_nbagv > 0
		SET @v_value = 1

     EXEC @retour= INT_SETVARIABLE @p_idvariable , @v_value
end

-----------------------------------------------------
-- AGV En direction ou en ZA2
-----------------------------------------------------
if (@p_idvariable = -6)
begin
	SET @v_value = 0	
	exec @v_nbagv = SPC_AGV_GETNBAGV @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE, @IDBASE_ZA2 , @p_idagv, 1, NULL
	IF @v_nbagv > 0
		SET @v_value = 1

     EXEC @retour= INT_SETVARIABLE @p_idvariable , @v_value
end

RETURN @retour
END

