SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Procedure pour remplir le stock A a fond
-- =============================================
CREATE PROCEDURE SPC_SIMU_REMPLISSAGE_DU_STOCK
AS
BEGIN
	/* Ajout de toutes les charges en stock*/	
	DECLARE @v_chg_idcharge int
	DECLARE @v_idBase bigint
	DECLARE @v_cote int
	DECLARE @v_nbcharge int
	DECLARE @v_nbchargemax int
	DECLARE c_charge CURSOR LOCAL FAST_FORWARD FOR 
	SELECT DISTINCT ADR_IDBASE, ADR_COTE
		FROM INT_ADRESSE
		WHERE ADR_IDTYPEMAGASIN = 3 and ADR_MAGASIN = 2 and ADR_IDSOUSBASE <> 0
	OPEN c_charge
	FETCH NEXT FROM c_charge INTO @v_idBase, @v_cote
	WHILE (@@FETCH_STATUS = 0)
	BEGIN	
		SET @v_nbcharge = 0
		IF @v_cote = 1
			SET @v_nbchargemax = 45
		ELSE
			SET @v_nbchargemax = 25

		WHILE (@v_nbcharge < @v_nbchargemax)
		BEGIN		
				EXECUTE [dbo].[INT_CREATECHARGE] @v_chg_idcharge OUTPUT
											  ,@v_chg_poids = 1000 ,@v_chg_hauteur = 1400 ,@v_chg_largeur = 1070 ,@v_chg_longueur = 1070
											  ,@v_chg_idsysteme = 65793 ,@v_chg_idbase = @v_idBase ,@v_chg_idsousbase = 65793
											  ,@v_chg_niveau = NULL ,@v_tag_idtypeagv = NULL ,@v_accesbase  = NULL ,@v_chg_orientation = 0 ,@v_chg_face   = 0
											  ,@v_chg_code  = NULL ,@v_chg_idproduit  = NULL ,@v_chg_idsymbole  = NULL ,@v_chg_idlegende  = NULL
											  ,@v_chg_idmenucontextuel  = NULL ,@v_chg_idvue  = NULL ,@v_chg_idgabarit  = NULL ,@v_chg_idemballage   = NULL
											  ,@v_chg_stabilite  = NULL ,@v_chg_position  = NULL ,@v_chg_vitessemaximale  = 0 ,@v_forcage = NULL
			SET @v_nbcharge =  @v_nbcharge +1
		END
		FETCH NEXT FROM c_charge INTO @v_idBase, @v_cote
	END
	CLOSE c_charge
	DEALLOCATE c_charge
END

