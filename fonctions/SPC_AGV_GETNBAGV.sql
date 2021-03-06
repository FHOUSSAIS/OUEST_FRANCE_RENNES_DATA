SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Author:		STEPIEN Fabrice
-- Create date: 19/03/2013
-- Description:	Indique le Nombre d'AGV
--	@v_tva_idtypevariable : Type de Variable (voir Déclaration Constantes)
--  @v_var_parametre : Identifiant de la Base ou de la Zone
--  @v_idAgv  :Identifiant de l'AGV qui appelle la fonction
--	@v_agvExclu : 1 si AGV exclu du calcul
--  @v_valideTypeAgv : 1 s'il faut tenir compte unqiuement du Type AGV (utile si plusieurs type d'AGV)
-- =============================================
CREATE FUNCTION [dbo].[SPC_AGV_GETNBAGV] 
(
	@v_tva_idtypevariable int,
	@v_var_parametre varchar(3500),
	@v_idAgv int,
	@v_agvExclu int,
	@v_valideTypeAgv int = 0
)
RETURNS int
AS
BEGIN
	declare @CODE_OK int = 0
	declare @CODE_KO int = 1
	declare @ETAT_ENATTENTE int = 1
	declare @DESC_ENVOYE int = 13
	declare @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE int = 1
	declare @TYPE_NOMBREAGVSDESTINATIONCOURANTEZONEPARAMETREE int = 2
	declare @TYPE_NOMBREAGVSDESTINATIONFUTUREBASEPARAMETREE int = 4
	declare @TYPE_NOMBREAGVSDESTINATIONFUTUREZONEPARAMETREE int = 5
	declare @TYPE_NOMBREAGVSORIGINEBASEPARAMETREE int = 11
	declare @TYPE_NOMBREAGVSORIGINEZONEPARAMETREE int = 12
	
	declare @v_crz_valeur int = 0,
			@typeAgv int = ( select IAG_TYPE from INFO_AGV where IAG_ID = @v_idAgv )
	
	IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONCOURANTEBASEPARAMETREE
	begin
		SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV 
		WHERE IAG_OPERATIONNEL = 'O' 
		AND   (    (                 IAG_BASE_DEST = @v_var_parametre
			         AND NOT EXISTS ( SELECT 1 FROM ORDRE_AGV 
								      WHERE ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE ) )
			    OR EXISTS ( SELECT 1 FROM ORDRE_AGV, TACHE 
							WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE
							AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE
							AND TAC_IDADRSYS = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME) AND TAC_IDADRBASE = @v_var_parametre ) )
		AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
		AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONCOURANTEZONEPARAMETREE
	begin
		SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre)
			AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE))
			OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE, ZONE_CONTENU WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE
			AND CZO_ZONE = @v_var_parametre AND TAC_IDADRSYS = CZO_ADR_KEY_SYS AND TAC_IDADRBASE = CZO_ADR_KEY_BASE))
			AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
			AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONFUTUREBASEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST = @v_var_parametre
				AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID))
				OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE
				AND TAC_IDADRSYS = (SELECT TOP 1 SYS_SYSTEME FROM SYSTEME) AND TAC_IDADRBASE = @v_var_parametre))
				AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 )  )
				AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end	
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSDESTINATIONFUTUREZONEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' AND ((IAG_BASE_DEST IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre)
				AND NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = IAG_ID))
				OR EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE, ZONE_CONTENU WHERE ORD_IDAGV = IAG_ID AND TAC_IDORDRE = ORD_IDORDRE
				AND CZO_ZONE = @v_var_parametre AND TAC_IDADRSYS = CZO_ADR_KEY_SYS AND TAC_IDADRBASE = CZO_ADR_KEY_BASE))
				AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 )  )
				AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSORIGINEBASEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV WHERE IAG_OPERATIONNEL = 'O' 
			AND (      ( IAG_BASE_ORIG = @v_var_parametre )
					or exists( select 1 from INT_TACHE_MISSION
							 join INT_MISSION_VIVANTE on TAC_IDMISSION = MIS_IDMISSION
							 where TAC_IDBASEEXECUTION = @v_var_parametre and TAC_IDETATTACHE = 5
							 and MIS_IDAGV = IAG_ID ) )
				AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
				AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	ELSE IF @v_tva_idtypevariable = @TYPE_NOMBREAGVSORIGINEZONEPARAMETREE
	begin
			SELECT @v_crz_valeur = COUNT(*) FROM INFO_AGV 
			WHERE IAG_OPERATIONNEL = 'O' 
			AND (    ( IAG_BASE_ORIG IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre) )
				  or exists( select 1 from INT_TACHE_MISSION
							 join INT_MISSION_VIVANTE on TAC_IDMISSION = MIS_IDMISSION
							 where TAC_IDBASEEXECUTION IN (SELECT CZO_ADR_KEY_BASE FROM ZONE_CONTENU WHERE CZO_ZONE = @v_var_parametre) and TAC_IDETATTACHE = 5
							 and MIS_IDAGV = IAG_ID ) )
			AND ( ( @v_agvExclu = 1 and IAG_ID <> @v_idAgv ) or ( @v_agvExclu = 0 ) )
			AND ( ( @v_valideTypeAgv = 1 and IAG_TYPE = @typeAgv ) or ( @v_valideTypeAgv = 0 ) )
	end
	
	return @v_crz_valeur
	
END

